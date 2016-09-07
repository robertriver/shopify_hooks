module ShopifyHooks
  class Railtie < Rails::Railtie

    rake_tasks do
      load 'tasks/shopify_hooks_tasks.rake'
    end

  end
end
