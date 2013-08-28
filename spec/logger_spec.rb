require File.dirname(__FILE__) + '/spec_helper'

class A22 # duck
  def logger_tag
    "some"
  end
  def full_name
  end
end

describe "Eye::Logger" do
  it "should use smart logger with auto prefix" do
    Eye::Process.logger.prefix.should == "Eye::Process"
    Eye.logger.prefix.should == "Eye"
    Eye::Checker.logger.prefix.should == "Eye::Checker"
    Eye::Checker.create(123, {:type => :cpu, :every => 5.seconds, :times => 1}, A22.new).logger.prefix.should == "some"
    Eye::Server.new(C.socket_path).logger.prefix.should == "<Eye::Server>"
    Eye::Controller.new.logger.prefix.should == "Eye"
    Eye::Process.new(C.p1).logger.prefix.should == "main:default:blocking process"
  end
end