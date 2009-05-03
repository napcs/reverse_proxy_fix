require File.dirname(__FILE__) + '/spec_helper'
require File.join(File.dirname(__FILE__), '..', 'lib',  '23')

describe "when BASE_URL is not set" do
  before(:each) do
    if Object.const_defined? 'BASE_URL'
      Object.send(:remove_const, 'BASE_URL') 
      ActionController.reset_asset_host_and_route_optimization
    end
  end
  
  it "should not raise a warning" do
    lambda { ActionController.check_mode_and_base }.should_not raise_error
  end
  
  it "should return false on check mode and base" do
    ActionController.check_mode_and_base.should be_false
  end
end
