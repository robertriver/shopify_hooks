# ShopifyHooks



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shopify_hooks'
```

And then execute:

    $ bundle

## Usage

Create a `initializers/shopify_hooks.rb` file

```
ShopifyHooks.configuration do |config|
  config.shopify_base_url = "https://little-store-of-testing.myshopify.com/"
  
  config.shopify_url = "https://#{ENV["shopify_api_key"]}:#{ENV["shopify_api_password"]}@little-store-of-testing.myshopify.com/admin"
  
  config.shopify_webhook_route = "https://00c6cc41.ngrok.io/api/shopify_hooks/"
  
  config.default_vendor = 'Mathews'
  
  config.shopify_shared_secret =  ENV['shopify_shared_secret']
  
  config.shopify_multipass_secret = ENV['shopify_multipass_secret']
  
  config.given_app_proc = Powertex.create_order_from_shopify
  
end   
```

Mount it  in `routes.rb`

	mount ShopifyHooks::Engine => '/api'
	
Include in a model 

ie: 

	include ShopifyHooks::Shopifyable	
	
### Shopifyable things

Including Shopifyable in a class will add afte_save and after_destroy callbacks to call the shopify API and do things. 

Look at the sorce code in `lib/shopify_hooks/shopifyable` for more info


### Other Methods

Accessing config variables

	ShopifyHooks::shopify_base_url returns => "https://little-store-of-testing.myshopify.com/"
	
Multipass Login 

	token = ShopifyHooks::ShopifyMultipass.new(ShopifyHooks.shopify_multipass_secret).generate_token({email:current_user.email})	

	redirect_to(ShopifyHooks::shopify_base_url + "account/login/multipass/#{token}")
	 


### Workers and Controllers 

This engine adds callback routes at 

	whereveryoumountit/ 
	
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
	
* So a post to `whereveryoumountit/shopify_hooks/products/create` will call `create_product` in the shopify_hooks_controller defined in this engine 
* The Controllers are at `app/controllers`

There are also workers created for creating orders and and keeping products up to date.

look in `app/workers/*` source code for more info.

This line in the shopify_hooks.rb initializer is how we tell shopify what to do after we create an order from shopify and it calls it's worker. This needs to be defined somewhere in the home app.

	config.given_app_proc = Powertex.create_order_from_shopify
	
ie `lib/modules/powertex.rb`

	class Powertex

	  PowertexApi::Api.initiate_connection(
    	  api_key:  ENV['powertex_api_key'],
	      username: ENV['powertex_username'],
    	  password: ENV['powertex_password']
	  )

	  def self.create_order_from_shopify
    	return Proc.new do |args|
			# Do something with args from order worker 
		  end
	  end

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
