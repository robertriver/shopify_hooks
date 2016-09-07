# module ShopifyHooks
  class ShopifyUpdateProductWorker < ActiveJob::Base
    # Product Updated in Shopify
    queue_as :default

    def perform(updated_product, found_product)
      found_product.type = updated_product["product_type"] || "Unknown Type"
      found_product.name = updated_product["title"]
      found_product.title = updated_product["title"]
      found_product.type = updated_product["product_type"]
      found_product.product_cat_list = updated_product["tags"].split(',').map { |word| word.strip }
      found_product.description = updated_product["body_html"]
      found_product.price = updated_product["variants"].first["price"]
      found_product.save
    end
  end
# end