require File.dirname(__FILE__) + '/../../spec_helper'

describe "Custom checks" do
  before :each do
    @c = Eye::Controller.new
    r = @c.load(fixture("dsl/custom_check.eye"))
    sleep 3
    @process = @c.process_by_name("1")
    @process.watchers.keys.should == [:check_alive, :check_custom_check]
  end

  it "should not restart" do
    dont_allow(@process).schedule(:restart)
    sleep 4
  end

  it "should restart" do
    proxy(@process).schedule(:restart, is_a(Eye::Reason))
    sleep 6
  end

end