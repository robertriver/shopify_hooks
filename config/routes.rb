ShopifyHooks::Engine.routes.draw do
  scope '/shopify_hooks' do
    scope 'products' do
      post '/create' => 'shopify_hooks/shopify_hooks#create_product'
      post '/update' => 'shopify_hooks/shopify_hooks#update_product'
    end
    scope 'orders' do
      post '/create' => 'shopify_hooks/shopify_hooks#create_order'
      post '/update' => 'shopify_hooks/shopify_hooks#update_order'
    end
  end
end