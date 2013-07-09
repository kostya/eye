require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl::Config" do

  it "logger" do
    conf = <<-E
      Eye.config do
        logger "/tmp/1.loG"
      end
    E
    Eye::Dsl.parse(conf).to_h.should == {:applications => {}, :settings => {:logger => "/tmp/1.loG"}}
  end

  it "should merge sections" do
    conf = <<-E
      Eye.config do
        logger "/tmp/1.log"
        logger_level 2
      end

      Eye.config do
        logger "/tmp/2.log"
      end

    E
    Eye::Dsl.parse(conf).to_h.should == {:applications => {}, :settings => {:logger => "/tmp/2.log",
      :logger_level => 2}}
  end

end