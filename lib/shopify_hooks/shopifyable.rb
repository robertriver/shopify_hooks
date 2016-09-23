require 'pry'
module ShopifyHooks
  module Shopifyable
    extend ActiveSupport::Concern
    included do

      # :description
      validates :title, :type, presence: true
      #
      after_save { |object| ShopifyActions::update(object) if shopify_product_attr_watchers_changed || object.shopify_product_id.nil? }

      after_destroy{ |object| ShopifyActions::destroy_object(object) }
      #
      def shopify_product_attr_watchers_changed
        self.title_changed?  rescue false || self.type_changed? rescue false  || self.description_changed? rescue false|| self.any_tags_changed? rescue false
      end

      def any_tags_changed?
        changed = self.tag_types.map { |type| send_list_changed(type) }
        changed.any? { |bool| bool === true }
      end

      private
      def send_list_changed(type)
        self.send((type.to_s.singularize + '_list_changed?').to_sym)
      end

    end
  end


  module ShopifyActions
    # extend ActiveSupport::Concern
    class << self

      @@shopify_calls = OpenStruct.new(current_call_count: 0, time_since_last: 0, time_last: Time.now)

      def save_object(shopify_object)
        begin
        check_shopify_calls
        if shopify_object.save
          puts 'Updating and/or creating on Shopify'
        else
          p "#{shopify_object.sku} had errors  #{shopify_object.errors.messages}"
        end
        rescue => e
          p e
          p '<<< Backtrace >>>>'
          p e.backtrace.join("\n")
        end
      end

      def check_shopify_calls
        @@shopify_calls.time_since_last = Time.now - @@shopify_calls.time_last
        if @@shopify_calls.current_call_count <= 2 || @@shopify_calls.time_since_last >= 2
          puts "returning"
          @@shopify_calls.time_last = Time.now
          @@shopify_calls.current_call_count += 1
          return
        else
          puts "Too Many Requests. looping til time is up"
          sleep(2 - @@shopify_calls.time_since_last)
          @@shopify_calls.current_call_count = 0
          check_shopify_calls
        end
      end

      def create_variant(object)
        new_variant = ShopifyAPI::Variant.new
        set_synced_variation_fields(new_variant, object)
        begin
          # Save to Shopify
          save_object(new_variant)
        rescue => e
          puts e
          # Add Errors to model to notify user that it did not persist to Shopify
          object.errors.add(:shopify_update, "Update or Create Failed. Error: #{e.message}")
        end
          # Only if object saves set the proper ID
          if object.shopify_variation_id == new_variant.id && !object.shopify_variation_id.nil?
            return
          else
            if object.is_default
              puts "DEFAULT"
              check_shopify_calls
              object.shopify_variation_id = ShopifyAPI::Product.find(new_variant.product_id).variants.first.id
            else
              if !new_variant.errors.messages.empty?
                CSV.open('public/errored_products.csv', 'a+') do |csv|
                  csv << new_variant.attributes.values.to_a + new_variant.errors.messages.values.to_a.flatten
                end
                check_shopify_calls
                found_shopify_variant = ShopifyAPI::Product.find(new_variant.product_id).variants.select do |variant|
                  variant.attributes['option1'] == new_variant.attributes['option1'].to_s &&
                  variant.attributes['option2'] == new_variant.attributes['option2'].to_s &&
                  variant.attributes['option3'] == new_variant.attributes['option3'].to_s
                end
                if found_shopify_variant.empty?
                  puts "SOMETHING HAPPENED WITH THIS PRODUCT AND MAY REQUIRE MANUAL INTERVENTION. Check the logs or error"
                else
                  puts "Already found on Shopify. Setting Variant ID to the same as Shopify"
                  object.shopify_variation_id = found_shopify_variant.first.id
                  object.save
                end
                return
              end
              object.shopify_variation_id = new_variant.id
            end
            object.save
          end
        # end
      end
      #
      def destroy_object(object)
        # Dont destroy just set to published_at = nil for products and set inventory to 0 for variants
        # Variants don't have unpublish/published
        begin
        case(true)
          when object.is_a?(Product)
            check_shopify_calls
            product = ShopifyAPI::Product.find(object.shopify_product_id)
            product.published_at = nil
            product.save
          when object.is_a?(ProductVariation)
            check_shopify_calls
            variant = ShopifyAPI::Variant.find(object.shopify_variation_id)
            variant.inventory_quantity = 0
            variant.save
          else
            raise('Not Shopify Variant or Product Error')
        end
        rescue => e
          puts "#{e.message}"
          return
        end
      end

      def deep_delete_product(product)
        ShopifyAPI::Variant.find(product.shopify_product_id).remove
      end

      def create_product(object)
        puts "CREATING PRODUCT"
        # ShopifyAPI::Base.site || set_shop
        new_product = ShopifyAPI::Product.new
        set_synced_fields(new_product, object)
        begin
          # Save to Shopify
          new_product.published_at = nil
          save_object(new_product)
        rescue => e
          # Add Errors to model to notify user that it did not persist to Shopify
          object.errors.add(:shopify_update, "Update or Create Failed. Error: #{e.message}")
        else
          # Only if object saves set the proper ID
          if object.shopify_product_id == new_product.id
            return true
          else
            object.shopify_product_id = new_product.id
            object.save
          end
        end
      end

      def all_tags_string(object)
        object.tag_types.map { |type| get_updated_tags(type, object) }.join(',')
      end


      def get_updated_tags(type, object)
        tags = get_tags_from_object(type, object)
        changes_array = tag_changes(type, object)
        current_tags_string = tags.flatten.map { |tag| tag.name }.join(',')
        changes_array.nil? ? current_tags_string : changes_array[1] # second index is the new changed string of tags
      end

      def find(object)
        case(true)
          when object.is_a?(Product)
            check_shopify_calls
            ShopifyAPI::Product.find(object.shopify_product_id)
          when object.is_a?(ProductVariation)
            check_shopify_calls
            ShopifyAPI::Variant.find(object.shopify_variation_id)
          else
            raise('Not Shopify Variant or Product Error')
        end
      end

      def update(object)
        if object.shopify_product_id.nil? && object.is_a?(Product)
          create_product(object)
        elsif !object.shopify_product_id.nil? && object.is_a?(Product)
          product = find(object)
          set_synced_fields(product, object)
        elsif object.shopify_variation_id.nil? && object.is_a?(ProductVariation)
          create_variant(object)
        elsif !object.shopify_variation_id.nil? && object.is_a?(ProductVariation)
          variant = find(object)
          set_synced_variation_fields(variant,object)
        end
      end

      private

      def set_shop
        ShopifyAPI::Base.site = ShopifyHooks.shopify_url
        ShopifyAPI::Shop.current
      end

      def set_synced_variation_fields(shopify_product, new_or_updated_product)
        shopify_product.sku =  new_or_updated_product.sku
        shopify_product.description =  (new_or_updated_product.try(:description) || new_or_updated_product.description)
        shopify_product.option1 =  new_or_updated_product.color.empty? ? 'Default Color' : new_or_updated_product.color
        shopify_product.option2 =  new_or_updated_product.size.empty? ? 'Default Size' : new_or_updated_product.size
        shopify_product.option3 =  new_or_updated_product.power_tex_id.nil? ? 'No PowerTex ID' : new_or_updated_product.power_tex_id
        shopify_product.inventory_quantity =  new_or_updated_product.quantity_available
        shopify_product.prefix_options[:product_id] = new_or_updated_product.product.shopify_product_id

          save_object(shopify_product)
      end

      def set_synced_fields(shopify_product, new_or_updated_product)
        shopify_product.sku =  new_or_updated_product.sku
        shopify_product.product_type = new_or_updated_product.try(:type) || ''
        shopify_product.title = new_or_updated_product.try(:title) || ''
        shopify_product.options = [
            {"name": "Color", 'value': new_or_updated_product.try(:color)|| 'Default Color'},
            {"name": "Size", 'value': new_or_updated_product.try(:size) || 'Default Size'},
            {"name": "PowerTexID", 'value': new_or_updated_product.try(:power_tex_id) || 'No Power Tex ID Set'}]

        shopify_product.body_html = new_or_updated_product.try(:description) # HTML for description
        shopify_product.vendor = ShopifyHooks.default_vendor || ''
        save_object(shopify_product) # Save to get access to Variants for certain Meta Data
      end

      def get_tags_from_object(type, object)
        object.send(type)
      end

      def tag_changes(type, object)
        object.send((type.to_s.singularize + '_list_change'))
      end

    end
  end


end