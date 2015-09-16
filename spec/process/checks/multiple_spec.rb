require File.dirname(__FILE__) + '/../../spec_helper'

describe "Multiple checks" do
  it "should create many checks with the same type" do
    @c = Eye::Controller.new
    r = @c.load(fixture("dsl/multiple_checks.eye"))
    sleep 3
    @process = @c.process_by_name("1")
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_cpu, :check_cpu9, :check_cpu3, :check_cpu_4]
    @process.watchers[:check_cpu][:subject].class.should == Eye::Checker::Cpu
    @process.watchers[:check_cpu9][:subject].class.should == Cpu9
    @process.watchers[:check_cpu3][:subject].class.should == Eye::Checker::Cpu
    @process.watchers[:check_cpu_4][:subject].class.should == Eye::Checker::Cpu
  end
end