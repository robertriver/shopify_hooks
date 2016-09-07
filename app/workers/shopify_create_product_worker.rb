# module ShopifyHooks
  class ShopifyCreateProductWorker < ActiveJob::Base
    queue_as :default

    def perform(new_or_updated_product)
      # Created A Product In Shopify - This Should Probably Be Discouraged.
      # Shopify doesn't store all the same values as us, so some things like category would have to be mapped to type or just 'New Product' so that
      # admins can see a New Product and Rena missing fields accordingly.
      product = Product.new
      product.category = "New Product"
      product.product_type_category = "New Product"
      product.shopify_product_id = new_or_updated_product["id"]
      product.name = new_or_updated_product["title"]
      product.title = new_or_updated_product["title"]
      product.type = new_or_updated_product["product_type"] || "Unknown Type"
      product.tag_list = new_or_updated_product["tags"].split(',').map { |word| word.strip }
      product.description = new_or_updated_product["body_html"]
      product.price = new_or_updated_product["variants"].first["price"]
      product.save
    end
  end
# end