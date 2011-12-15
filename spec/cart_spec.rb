require File.expand_path("../spec_helper", __FILE__)

Cart     = MerchantSidekick::ShoppingCart::Cart
LineItem = MerchantSidekick::ShoppingCart::LineItem

describe Cart do

  before(:each) do
    @cart = Cart.new('USD')
  end

  def create_user(options = {})
    values = {:name => "Sam User", :email => "sam@example.com", :type => "BuyingUser"}
    UserDummy.create! values.merge(options)
  end

  def create_product(options = {})
    values = {:title => "Super Duper Widget", :cents => 2995, :currency => "USD"}
    ProductDummy.create! values.merge(options)
  end

  it "should initialize" do
    # defaults
    cart = Cart.new
    cart.currency.should == 'USD'
    cart.total_price == Money.new(0, 'USD')

    # user and currency
    cart = Cart.new('EUR')
    cart.currency.should == 'EUR'
    cart.total_price == Money.new(0, 'EUR')
  end

  it "should add one product" do
    transaction do
      widget = create_product
      @cart.add(widget)
      @cart.should_not be_empty
      @cart.total.to_s.should == "29.95"
      @cart.line_items.first.name.should == widget.title
      @cart.line_items.first.item_number.should == widget.id
    end
  end

  it "should find an item by product" do
    transaction do
      widget = create_product
      @cart.add(widget)
      item = @cart.find(:first, widget)
      item.should == @cart.line_items[0]
    end
  end

  it "should not find an item by product" do
    transaction do
      widget = create_product
      @cart.add(widget)
      @cart.remove(widget)
      item = @cart.find(:first, widget)
      item.should be_nil
      @cart.should be_empty
    end
  end

  it "should add a card line item" do
    transaction do
      widget = create_product
      line_item = @cart.cart_line_item(widget)
      @cart.add(line_item)
      @cart.should_not be_empty
      @cart.total.to_s.should == "29.95"
      @cart.line_items.first.name.should == widget.title
      @cart.line_items.first.item_number.should == widget.id
    end
  end

  it "should add multiple products separately" do
    transaction do
      widget = create_product
      knob   = create_product(:title => "Shiny Knob", :cents => 399, :currency => "USD")
      @cart.add(widget)
      @cart.total.to_s.should == "29.95"
      @cart.add(widget)
      @cart.line_items.size.should == 1
      @cart.total.to_s.should == "59.90"
      @cart.add(knob)
      @cart.should_not be_empty
      @cart.line_items.size.should == 2
      @cart.total.to_s.should == "63.89"
    end
  end

  it "should add multiple products at the same time" do
    transaction do
      widget = create_product
      knob   = create_product(:title => "Shiny Knob", :cents => 399, :currency => "USD")
      @cart.add(widget, 2)
      @cart.line_items.size.should == 1
      @cart.total.to_s.should == "59.90"
      @cart.add(knob, 3)
      @cart.line_items.size.should == 2
      @cart.total.to_s.should == "71.87"
    end
  end

  it "should remove one cart item by product" do
    transaction do
      widget = create_product
      @cart.add(widget)
      @cart.line_items.size.should == 1
      deleted_line_item = @cart.remove(widget)
      deleted_line_item.class.should == MerchantSidekick::ShoppingCart::LineItem
      deleted_line_item.product == widget
      @cart.should be_empty
      @cart.total.to_s.should == "0.00"
    end
  end

  it "should remove one cart item by cart_line_item" do
    transaction do
      widget = create_product
      line_item = @cart.add(widget)
      line_item.class.should == MerchantSidekick::ShoppingCart::LineItem
      @cart.line_items.size.should == 1
      deleted_line_item = @cart.remove(line_item)
      deleted_line_item.class.should == MerchantSidekick::ShoppingCart::LineItem
      deleted_line_item.product == widget
      @cart.should be_empty
      @cart.total.to_s.should == "0.00"
    end
  end

  it "should remove multiple cart item by product" do
    transaction do
      widget = create_product
      @cart.add(widget)
      @cart.add(widget)
      @cart.line_items.size.should == 1
      @cart.total.to_s.should == "59.90"
      @cart.remove(widget)
      @cart.line_items.size.should == 0
      @cart.total.to_s.should == "0.00"
    end
  end

  it "should empty all cart line items" do
    transaction do
      widget = create_product
      knob = create_product(:title => "Shiny Knob", :cents => 399, :currency => "USD")
      6.times do
        @cart.add(widget)
      end
      @cart.line_items.size.should == 1
      @cart.total.to_s.should == "179.70"
      6.times do
        @cart.add(knob)
      end
      @cart.line_items.size.should == 2
      @cart.total.to_s.should == "203.64"
      @cart.empty!
      @cart.should be_empty
      @cart.line_items.size.should == 0
      @cart.total.to_s.should == "0.00"
    end
  end

  it "should update the cart by cart line item" do
    transaction do
      widget = create_product
      knob = create_product(:title => "Shiny Knob", :cents => 399, :currency => "USD")
      @cart.add(widget)
      @cart.add(knob)
      @cart.total.to_s.should == "33.94"
      item = @cart.update(@cart.line_items[0], 2)
      item.should == @cart.line_items[0]
      item = @cart.update(@cart.line_items[1], 3)
      item.should == @cart.line_items[1]
      @cart.total.to_s.should == "71.87"
      tbr_item = @cart.find(:first, @cart.line_items[1])
      item = @cart.update(tbr_item, 0)
      item.should == tbr_item
      @cart.total.to_s.should == "59.90"
    end
  end

  it "should update the cart by product" do
    transaction do
      widget = create_product
      knob = create_product(:title => "Shiny Knob", :cents => 399, :currency => "USD")
      @cart.add(widget)
      @cart.add(knob)
      @cart.total.to_s.should == "33.94"
      item = @cart.update(widget, 2)
      item.should_not be_nil
      item.product.should == @cart.line_items[0].product

      item = @cart.update(knob, 3)
      item.should_not be_nil
      item.product.should == @cart.line_items[1].product

      @cart.total.to_s.should == "71.87"
      tbr_item = @cart.find(:first, knob)
      item = @cart.update(knob, 0)
      item.should == tbr_item
      @cart.total.to_s.should == "59.90"
    end
  end

  it "should serialize and deserialize the cart" do
    transaction do
      widget = create_product
      @cart.add(widget)
      @cart.line_items[0].product.should == widget
      # serialize
      session = @cart.to_yaml
      # deserialize
      session_cart = YAML.load(session)
      session_cart.line_items.size.should == 1
      session_cart.line_items[0].product.should == widget
    end
  end

end
