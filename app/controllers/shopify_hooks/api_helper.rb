module ShopifyHooks
  module ApiHelper
    def verify_webhook(data, hmac_header)
      digest = OpenSSL::Digest::Digest.new('sha256')
      calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, ENV["shopify_shared_secret"], data)).strip
      calculated_hmac == hmac_header
    end
  end
end