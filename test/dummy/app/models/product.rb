class Product < ActiveRecord::Base
    include ShopifyHooks::Shopifyable
    self.abstract_class = true
end