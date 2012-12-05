# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::SystemResources" do
    
  it "should get memory" do
    x = Eye::SystemResources.memory_usage($$)
    x.should > 100
    x.should < 300_000
  end

  it "should get memory2" do
    x = Eye::SystemResources.memory_usage2($$)
    x.should > 100
    x.should < 800_000
  end

  it "should get cpu" do
    x = Eye::SystemResources.cpu_usage($$)
    x.should >= 0
    x.should < 100
  end

  it "should get childs" do
    x = Eye::SystemResources.childs($$)
    x.is_a?(Array).should == true
    x.first.should > 0
    x.size.should > 0
    x.sum.should > 0
  end

  it "should get cmd" do
    x = Eye::SystemResources.cmd($$)
    x.should match(/ruby/)
    x.should match(/rspec/)
  end

  it "should cache and update when interval" do
    silence_warnings{ Eye::SystemResources::PsAxActor::UPDATE_INTERVAL = 2 }

    x1 = Eye::SystemResources.cmd($$)
    x2 = Eye::SystemResources.cmd($$)
    x1.should == x2

    sleep 1
    x3 = Eye::SystemResources.cmd($$)
    x1.should == x3

    # change the cmd
    $0 = "ruby rspec ..."

    sleep 1.5
    x4 = Eye::SystemResources.cmd($$)
    x1.should == x4 # first value is old

    x5 = Eye::SystemResources.cmd($$)
    x1.should_not == x5 # seconds is new
  end

end
