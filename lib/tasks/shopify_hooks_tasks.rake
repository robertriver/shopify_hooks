# Task to Set Up Shopify Webhook Endpoints
require 'pg'
require 'helpers/shopify_rake_helper'

namespace :shopify_tasks do
  desc "Create Webhooks For Products"
  task :create_product_webhooks => :environment do
    ShopifyRakeHelper::set_shop

    topics = [
        "products/update",
        "products/create",
    ]
    # Dunno if we want to allow deleting in Shopify to delete our data too..
    # "products/delete"
    topics.each do |topic|
      ShopifyRakeHelper::create_webhook(topic)
    end
  end


  desc "Create Webhooks For Refunds"
  task :create_refund_webhooks => :environment do
    ShopifyRakeHelper::set_shop
    topics = [
        "refunds/create",
    ]
    topics.each do |topic|
      ShopifyRakeHelper::create_webhook(topic)
    end
  end

  desc "Create Webhooks For Orders"
  task :create_order_webhooks => :environment do
    ShopifyRakeHelper::set_shop
    topics = [
        "orders/create",
    ]
    topics.each do |topic|
      ShopifyRakeHelper::create_webhook(topic)
    end
  end

  desc "Update/Create All Products"
  task :products_update_create => :environment do
    ShopifyRakeHelper::set_shop
    errored_products = 0
    Product.all.each_with_index do |product,i|
      # This just saves each product to validate and then by default will call shopify because it has an after-save hook.
      product.type = Product::PRODUCT_TYPE_MAPPINGS[product.product_type.first.name]
      plan_type    = product.product_cat.map{|x| Product::CATEGORY_OLD_NAMES_TO_NEW[x.name]}.compact.first
      if product.type == 'subscription' && plan_type.nil?
        product.category = 'subscription'
      elsif product.type == 'plan' && plan_type.nil?
        product.category = 'general-training'
      else
        product.category = plan_type
      end
      # Sleep for 5 seconds every 15 requests so we dont get blocked by api max requests
      if i % 15 == 0
        puts "sleeping for API Request to Shopify"
        sleep 5
      end
      if !product.save
        errored_products += 1
        puts "#{product.id} had errors : #{errored_products} Total"
        puts product.errors
      end
    end
    puts "#{errored_products} Total Errored Products"
  end

  desc "remove all webhooks"
  task :remove_all_webhooks => :environment do
    ShopifyRakeHelper::set_shop
    ShopifyAPI::Webhook.all.map{ |hook| hook.destroy}
  end

  desc "Create All Webhooks"
  task :create_all_webhooks => :environment do
    Rake::Task["environment"].invoke
    Rake::Task["shopify_tasks:create_order_webhooks"].invoke
    Rake::Task["shopify_tasks:create_product_webhooks"].invoke
    Rake::Task["shopify_tasks:create_refund_webhooks"].invoke
  end

end