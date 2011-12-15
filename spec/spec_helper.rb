require "bundler/setup"
require "active_record"
require "rspec"
require "sqlite3"
require "merchant_sidekick"



# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
ActiveRecord::Migration.verbose = false

require "merchant_sidekick/migrations/billing"
require "merchant_sidekick/migrations/addressable"
require "merchant_sidekick/migrations/shopping_cart"

def migration
  yield ActiveRecord::Migration
end

def transaction
  ActiveRecord::Base.connection.transaction do
    yield
    raise ActiveRecord::Rollback
  end
end

migration do |m|
  m.create_table :product_dummies, :force => true do |t|
    t.column :title, :string
    t.column :description, :text
    t.column :image_url, :string
    t.column :cents, :integer
    t.column :currency, :string, :null => false, :default => 'USD'
  end

  #--- user dummy
  m.create_table :user_dummies, :force => true do |t|
    t.column :name, :string
    t.column :email, :string
    t.column :type, :string
  end
end


CreateMerchantSidekickBillingTables.up
CreateMerchantSidekickAddressableTables.up
CreateMerchantSidekickShoppingCartTables.up

#--- test dummy class definitions
class ProductDummy < ActiveRecord::Base
  money :price
  acts_as_sellable

  # weird cart serialization workaround
  def target
    true
  end

end

at_exit {ActiveRecord::Base.connection.disconnect!}