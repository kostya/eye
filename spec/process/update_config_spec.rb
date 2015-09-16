require File.dirname(__FILE__) + '/../spec_helper'

describe "#update_config" do
  before :each do
    @cfg = C.p3.merge(:checks => join(C.check_mem, C.check_cpu), :monitor_children => {})
    start_ok_process(@cfg)
    sleep 6
  end

  after :each do
    @process.stop if @process
  end

  it "update only env" do
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_children, :check_memory, :check_cpu]
    @process.children.keys.size.should == 3
    child_pids = @process.children.keys
    @process[:environment]["PID_NAME"].should be

    @process.update_config(@cfg.merge(:environment => @cfg[:environment].merge({"ENV2" => "SUPER"})))
    sleep 5

    @process.state_name.should == :up
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_children, :check_memory, :check_cpu]
    @process.children.keys.size.should == 3
    @process.children.keys.should == child_pids
    @process[:environment]["ENV2"].should == "SUPER"
    @process.pid.should == @pid
  end

  it "update watchers" do
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_children, :check_memory, :check_cpu]
    @process.children.keys.size.should == 3
    child_pids = @process.children.keys

    @process.update_config(@cfg.merge(:checks => C.check_mem))
    sleep 5

    @process.state_name.should == :up
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_children, :check_memory]
    @process.children.keys.size.should == 3
    @process.children.keys.should == child_pids
    @process.pid.should == @pid
  end

  it "when disable monitor_children they should remove" do
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_children, :check_memory, :check_cpu]
    @process.children.keys.size.should == 3
    child_pids = @process.children.keys

    @process.update_config(@cfg.merge(:monitor_children => nil))
    sleep 5

    @process.state_name.should == :up
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_memory, :check_cpu]
    @process.children.keys.size.should == 0
    @process.pid.should == @pid
  end

end


