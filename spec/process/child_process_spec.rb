require File.dirname(__FILE__) + '/../spec_helper'

describe "ChildProcess" do

  describe "starting, monitoring" do
    after :each do
      @process.stop if @process
    end

    it "should monitoring when process has childs and enable option" do
      cfg = C.p3.merge(:monitor_children => {})
      start_ok_process(cfg)
      sleep 5 # ensure that childs finds

      @process.state_name.should == :up
      @process.childs.keys.should_not == []
      @process.childs.keys.size.should == 3
      @process.watchers.keys.should == [:check_alive, :check_childs]

      child = @process.childs.values.first
      child.watchers.keys.should == []
    end

    it "should not monitoring when process has childs and disable option" do
      start_ok_process(C.p3)
      @process.childs.should == {}
      @process.watchers.keys.should == [:check_alive]
    end

    it "should not monitoring when process has no childs and enable option" do
      start_ok_process(C.p1.merge(:monitor_children => {}))
      @process.childs.should == {}
      @process.watchers.keys.should == [:check_alive, :check_childs]
    end

    it "when one of child is die, should update list" do
      start_ok_process(C.p3.merge(:monitor_children => {}, :childs_update_period => Eye::SystemResources::cache.expire + 1))
      @process.watchers.keys.should == [:check_alive, :check_childs]

      sleep 5 # ensure that childs finds

      #p @process.childs
      pids = @process.childs.keys.sort

      # one of the child is just die
      died_pid = pids.sample
      die_process!(died_pid, 9)

      # sleep enought for update list
      sleep (Eye::SystemResources::cache.expire * 2 + 1).seconds

      new_pids = @process.childs.keys.sort

      pids.should_not == new_pids
      (pids - new_pids).should == [died_pid]
      (new_pids - pids).size.should == 1
    end

    it "all childs is die, should update list" do
      start_ok_process(C.p3.merge(:monitor_children => {}, :childs_update_period => Eye::SystemResources::cache.expire + 1))
      @process.watchers.keys.should == [:check_alive, :check_childs]

      sleep 5 # ensure that childs finds

      #p @process.childs
      master_pid = @process.pid
      pids = @process.childs.keys.sort

      # one of the child is just die
      Eye::System.execute("kill -HUP #{master_pid}")

      # sleep enought for update list
      sleep (Eye::SystemResources::cache.expire * 2 + 2).seconds

      new_pids = @process.childs.keys.sort

      master_pid.should == @process.pid
      new_pids.size.should == 3
      (pids - new_pids).should == pids
      (new_pids - pids).should == new_pids
    end

    it "when process stop, childs cleans" do
      start_ok_process(C.p3.merge(:monitor_children => {}, :childs_update_period => Eye::SystemResources::cache.expire + 1))
      sleep 5 # ensure that childs finds

      pid = @process.pid
      @process.watchers.keys.should == [:check_alive, :check_childs]
      @process.childs.size.should == 3

      @process.stop
      sleep 2
      @process.watchers.keys.should == []
      @process.childs.size.should == 0

      Eye::System.pid_alive?(pid).should == false
    end

  end

  describe "add_or_update_childs" do
    before :each do
      start_ok_process(C.p1.merge(:monitor_children => {}))
    end

    it "add new childs, update && remove" do
      stub(Eye::SystemResources).childs(@process.pid){ [3,4,5] }
      @process.add_or_update_childs
      @process.childs.keys.sort.should == [3,4,5]

      stub(Eye::SystemResources).childs(@process.pid){ [3,5,6] }
      @process.add_or_update_childs
      @process.childs.keys.sort.should == [3,5,6]

      stub(Eye::SystemResources).childs(@process.pid){ [3,5] }
      @process.add_or_update_childs
      @process.childs.keys.sort.should == [3,5]

      stub(Eye::SystemResources).childs(@process.pid){ [6,7] }
      @process.add_or_update_childs
      @process.childs.keys.sort.should == [6,7]

      @process.remove_childs
      @process.childs.should == {}
    end
  end

end