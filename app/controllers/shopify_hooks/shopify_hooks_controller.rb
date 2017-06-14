module ShopifyHooks
  # ShopifyHooks::ShopifyHooksBaseController
  class ShopifyHooksController < ShopifyHooksBaseController
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    # protect_from_forgery with: :exception
    # skip_before_filter :verify_authenticity_token

    # create/delete/disable/enable/update
    # def customers
    # end

    def create_refund
      shopify_refund = params.as_json
      user_email = shopify_refund["email"]
      ShopifyRefundWorker.perform_later(user_email,shopify_refund)
      render json: {status: 200}
    end

    def create_order
      shopify_order = params.as_json
      user_email = shopify_order["email"]
      ShopifyOrderWorker.perform_later(user_email,shopify_order)
      render json: {status: 200}
    end

    def create_order_paid
      shopify_order = params.as_json
      user_email = shopify_order["email"]
      ShopifyOrderPaidWorker.perform_later(user_email,shopify_order)
      render json: {status: 200}
    end

    def create_order_fulfilled
      shopify_order = params.as_json
      user_email = shopify_order["email"]
      ShopifyOrderFulfilledWorker.perform_later(user_email,shopify_order)
      render json: {status: 200}
    end

    def create_product(new_or_updated_product = false)
      if !new_or_updated_product
        new_or_updated_product = params.as_json
      end
      ShopifyCreateProductWorker.perform_later(new_or_updated_product)
      render json: {status: 200}
    end

    def update_product
      updated_product = params.as_json
      found_product = Product.find_by(:shopify_product_id => updated_product["id"])
      if found_product
        ShopifyUpdateProductWorker.perform_later(updated_product, found_product)
      else
        # In case we update a product that isn't in our database for some reason it should get created.
        ShopifyCreateProductWorker.perform_later(updated_product)
      end
      render json: {status: 200}
    end

  end

end