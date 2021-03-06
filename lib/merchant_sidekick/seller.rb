module MerchantSidekick
  module Seller #:nodoc:

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods

      # Defines helper methods for a person selling items.
      #
      # E.g.
      #
      #   class Merchant
      #     acts_as_seller
      #     ...
      #   end
      #
      #   # Selling a product to @customer
      #   @merchant.sell_to @customer, @products
      #   
      #   # Alternative syntax
      #   @merchant.sell @products, :to => @customer
      #
      def acts_as_seller(options={})
        include MerchantSidekick::Seller::InstanceMethods
        has_many :orders, :as => :seller, :dependent => :destroy, :class_name => "::MerchantSidekick::Order"
        has_many :invoices, :as => :seller, :dependent => :destroy, :class_name => "::MerchantSidekick::Invoice"
        has_many :sales_orders, :as => :seller, :class_name => "::MerchantSidekick::SalesOrder"
        has_many :sales_invoices, :as => :seller, :class_name => "::MerchantSidekick::SalesInvoice"
      end
    end

    module InstanceMethods

      def sell_to(buyer, *arguments)
        sell(arguments, :to => buyer)
      end

      # Sell sellables (line_items) and add them to a sales order
      # The seller will be this person.
      #
      # e.g.
      #
      #   seller.sell(@product, :buyer => @buyer)
      #
      def sell(*arguments)
        sellables = []
        options = default_sell_options

        # distinguish between options and attributes
        arguments = arguments.flatten
        arguments.each do |argument|
          case argument.class.name
          when 'Hash'
            options.merge! argument
          else
            sellables << (argument.is_a?(MerchantSidekick::ShoppingCart::Cart) ? argument.line_items : argument)
          end
        end
        sellables.flatten!
        sellables.reject! {|s| s.blank?}

        raise ArgumentError.new("No sellable (e.g. product) model provided") if sellables.empty?
        raise ArgumentError.new("Sellable models must have a :price") unless sellables.all? {|sellable| sellable.respond_to? :price}

        self.sales_orders.build do |so|
          so.buyer = options[:to]
          so.build_addresses

          sellables.each do |sellable|
            if sellable && sellable.respond_to?(:before_add_to_order)
              sellable.send(:before_add_to_order, self)
              sellable.reload unless sellable.new_record?
            end
            li = LineItem.new(:sellable => sellable, :order => so)
            so.line_items.push(li)
            sellable.send(:after_add_to_order, self) if sellable && sellable.respond_to?(:after_add_to_order)
          end
          self
        end
      end

      protected

      # override in model, e.g. :to => @customer
      def default_sell_options
        {}
      end

    end
  end
end
