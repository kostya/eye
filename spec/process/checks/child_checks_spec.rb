require File.dirname(__FILE__) + '/../../spec_helper'

describe "ChildProcess" do

  describe "starting, monitoring" do
    after :each do
      @process.stop if @process
    end

    it "should just monitoring, and do nothin" do
      start_ok_process(C.p3.merge(:monitor_children => {:checks => join(C.check_mem, C.check_cpu)}))
      sleep 6

      @process.state_name.should == :up
      @process.childs.keys.should_not == []
      @process.childs.keys.size.should == 3
      @process.watchers.keys.should == [:check_alive, :check_childs]

      @childs = @process.childs.values
      @childs.each do |child|
        child.watchers.keys.should == [:check_memory, :check_cpu]
        dont_allow(child).schedule :restart
      end

      sleep 7
    end

    it "should check childs even when one of them respawned" do
      start_ok_process(C.p3.merge(:monitor_children => {:checks => join(C.check_mem, C.check_cpu)}, :childs_update_period => Eye::SystemResources::PsAxActor::UPDATE_INTERVAL + 1)) 
      @process.watchers.keys.should == [:check_alive, :check_childs]

      sleep 6 # ensure that childs finds

      @process.childs.size.should == 3

      # now restarting 
      died = @process.childs.keys.sample
      die_process!(died, 9)

      # sleep enought for update list
      sleep (Eye::SystemResources::PsAxActor::UPDATE_INTERVAL * 2 + 3).seconds

      @process.childs.size.should == 3
      @process.childs.keys.should_not include(died)

      @childs = @process.childs.values
      @childs.each do |child|
        child.watchers.keys.should == [:check_memory, :check_cpu]
        dont_allow(child).schedule :restart
      end
    end

    it "some child get condition" do
      start_ok_process(C.p3.merge(:monitor_children => {:checks => 
        join(C.check_mem, C.check_cpu(:below => 50, :times => 2))}))
      sleep 6

      @process.childs.size.should == 3

      @childs = @process.childs.values
      crazy = @childs.shift

      @childs.each do |child|
        child.watchers.keys.should == [:check_memory, :check_cpu]
        dont_allow(child).schedule :restart
      end

      stub(Eye::SystemResources).cpu(crazy.pid){ 55 }
      stub(Eye::SystemResources).cpu(anything){ 5 }


      crazy.watchers.keys.should == [:check_memory, :check_cpu]
      mock(crazy).notify(:crit, "Bounded cpu(50%): [*55%, *55%] send to :restart")
      mock(crazy).schedule :restart, anything

      sleep 4
    end
  end
end