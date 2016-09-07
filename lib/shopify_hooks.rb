require 'helpers/configuration'
require 'shopify_hooks/engine'
require 'shopify_api'
require 'shopify_hooks/shopifyable'
require 'shopify_hooks/shopify_multipass'
require 'shopify_hooks/railtie' if defined?(Rails)
module ShopifyHooks
  extend Configuration

  define_setting :shopify_base_url,true,  "https://little-store-of-testing.myshopify.com/"
  define_setting :shopify_url, true, "https://#{ENV["shopify_api_key"]}:#{ENV["shopify_api_password"]}@little-store-of-testing.myshopify.com/admin"
  define_setting :shopify_webhook_route, true,  "https://9c14cb17.ngrok.io/shopify_hooks"
  define_setting :default_vendor, false, 'FDL'
  define_setting :shopify_shared_secret,true
  define_setting :shopify_multipass_secret,true
  define_setting :given_app_proc, true


end
