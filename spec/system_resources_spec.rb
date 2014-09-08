require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::SystemResources" do
  before :each do
    Eye::SystemResources.cache.clear
  end

  it "should get memory" do
    x = Eye::SystemResources.memory($$)
    x.should > 20.megabytes
    x.should < 300.megabytes
  end

  it "should get cpu" do
    x = Eye::SystemResources.cpu($$)
    x.should >= 0
    x.should <= 100
  end

  it "should get cputime" do
    x = Eye::SystemResources.cputime($$)
    x.should >= 0
    x.should <= 30 * 60
  end

  it "when unknown pid" do
    pid = 12342341
    Eye::SystemResources.cpu(pid).should == nil
    Eye::SystemResources.memory(pid).should == nil
    Eye::SystemResources.children(pid).should == []

    pid = nil
    Eye::SystemResources.cpu(pid).should == nil
    Eye::SystemResources.memory(pid).should == nil
    Eye::SystemResources.start_time(pid).should == nil
    Eye::SystemResources.children(pid).should == []
  end

  it "should get start time" do
    x = Eye::SystemResources.start_time($$)
    x.should >= 1000000000
    x.should <= 2000000000
  end

  it "should get children" do
    @pid = fork { at_exit{}; sleep 3; exit }
    Process.detach(@pid)
    sleep 0.5
    x = Eye::SystemResources.children($$)
    x.class.should == Array
    x.should include(@pid)
  end

  it "should get leaf_child" do
    @pid = fork { at_exit{}; sleep 3; exit }
    Process.detach(@pid)
    sleep 0.5
    x = Eye::SystemResources.leaf_child($$)
    x.should == @pid
  end

  it "should cache and update when interval" do
    Eye::SystemResources.cache.setup_expire(1)

    stub(Eye::Sigar).proc_mem { OpenStruct.new(:resident => 1240000) }

    x1 = Eye::SystemResources.memory($$)
    x2 = Eye::SystemResources.memory($$)
    x1.should == x2

    stub(Eye::Sigar).proc_mem { OpenStruct.new(:resident => 1230000) }

    sleep 0.5
    x3 = Eye::SystemResources.memory($$)
    x1.should == x3

    sleep 0.8
    x4 = Eye::SystemResources.memory($$)
    x1.should_not == x4 # first value is new
  end

end
