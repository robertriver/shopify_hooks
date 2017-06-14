require 'jsonpath'
class ShopifyOrderFulfilledWorker < ActiveJob::Base
  # Order Successfully placed in Shopify
  queue_as :default

  def perform(user_email,shopify_order)
    shopify_customer = ShopifyAPI::Customer.search(query: user_email).first
    ShopifyHooks::order_fulfilled_proc.call({order:shopify_order, customer: shopify_customer})
  end

  def user_by_lower(user_email)
    User.find_by('lower(user_email) = ?', user_email.downcase)
  end

end