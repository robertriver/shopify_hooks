# module ShopifyHooks
require 'jsonpath'
# module ShopifyHooks
class ShopifyRefundWorker < ActiveJob::Base
  # Refund Created in Shopify
  queue_as :default

  def perform(user_email,refund)
    shopify_customer = ShopifyAPI::Customer.search(query: user_email).first
    ShopifyHooks::refund_proc.call({refund:refund, customer: shopify_customer})
  end

  def user_by_lower(user_email)
    User.find_by('lower(user_email) = ?', user_email.downcase)
  end

end
# end