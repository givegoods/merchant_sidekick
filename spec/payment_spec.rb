require File.expand_path("../spec_helper", __FILE__)

describe "A payment" do

  it "should belong to a payable" do
    lambda { MerchantSidekick::Payment.new.should respond_to(:payable) }.should_not raise_error
  end

  it "should have an amount" do
    MerchantSidekick::Payment.new.should respond_to(:amount)
  end

end

