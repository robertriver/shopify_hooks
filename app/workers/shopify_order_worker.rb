# module ShopifyHooks
require 'jsonpath'
# module ShopifyHooks
class ShopifyOrderWorker < ActiveJob::Base
  # Order Successfully placed in Shopify
  queue_as :default

  def perform(user_email,shopify_order)
    shopify_customer = ShopifyAPI::Customer.where(email: user_email).first
    variant_ids = json_product_id_path(shopify_customer)
    ShopifyHooks::given_app_proc.call({shopify_ids: variant_ids,order:shopify_order, customer: shopify_customer})
  end


  def json_product_id_path(shopify_customer)
    path = JsonPath.new('$..variant_id')
    json = shopify_customer.orders.to_json
    shopify_ids = path.on(json)
  end

  def user_by_lower(user_email)
    User.find_by('lower(user_email) = ?', user_email.downcase)
  end

end
# end