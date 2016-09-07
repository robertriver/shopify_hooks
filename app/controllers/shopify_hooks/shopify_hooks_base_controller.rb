module ShopifyHooks
  class ShopifyHooksBaseController < ActionController::Base
    include ShopifyHooks::ApiHelper
    ActionController::Renderers::All
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    # protect_from_forgery with: :exception
    # skip_before_filter :verify_authenticity_token

    # before_filter :authenticate

    protected
    def authenticate
      if request.env["HTTP_X_SHOPIFY_HMAC_SHA256"]
        verify_webhook(request.body.read, request.env["HTTP_X_SHOPIFY_HMAC_SHA256"])
      else
        authenticate_or_request_with_http_token do |token, options|
          puts 'HERE it is'
          AdminUser.find_by(auth_token: token)
        end
      end
    end
  end
end

