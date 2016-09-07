module ShopifyRakeHelper

  def self.set_shop
    ShopifyAPI::Base.site =  ShopifyHooks.shopify_url
    ShopifyAPI::Shop.current
  end

  def self.create_webhook(topic)
    webhook = ShopifyAPI::Webhook.new
    webhook.topic   = topic
    webhook.format  = "json"
    webhook.address =  ShopifyHooks.shopify_webhook_route + "#{topic}"
    webhook.save
    p "Webhook Saved For #{webhook.topic} @ #{webhook.address}"
  end


end