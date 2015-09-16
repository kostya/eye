require File.dirname(__FILE__) + '/../spec_helper'

describe "ChildProcess" do

  describe "starting, monitoring" do
    after :each do
      @process.stop if @process
    end

    it "should monitoring when process has children and enable option" do
      cfg = C.p3.merge(:monitor_children => {})
      start_ok_process(cfg)
      sleep 5 # ensure that children are found

      @process.state_name.should == :up
      @process.children.keys.should_not == []
      @process.children.keys.size.should == 3
      @process.watchers.keys.should == [:check_alive, :check_identity, :check_children]

      child = @process.children.values.first
      child[:notify].should == { "abcd" => :warn }
      child.watchers.keys.should == []
    end

    it "should not monitoring when process has children and disable option" do
      start_ok_process(C.p3)
      @process.children.should == {}
      @process.watchers.keys.should == [:check_alive, :check_identity]
    end

    it "should not monitoring when process has no children and enable option" do
      start_ok_process(C.p1.merge(:monitor_children => {}))
      @process.children.should == {}
      @process.watchers.keys.should == [:check_alive, :check_identity, :check_children]
    end

    it "when one child dies, should update list" do
      start_ok_process(C.p3.merge(:monitor_children => {}, :children_update_period => Eye::SystemResources::cache.expire + 1))
      @process.watchers.keys.should == [:check_alive, :check_identity, :check_children]

      sleep 5 # ensure that children are found

      #p @process.children
      pids = @process.children.keys.sort

      # just one child dies
      died_pid = pids.sample
      die_process!(died_pid, 9)

      # sleep enought for update list
      sleep (Eye::SystemResources::cache.expire * 2 + 1).seconds

      new_pids = @process.children.keys.sort

      pids.should_not == new_pids
      (pids - new_pids).should == [died_pid]
      (new_pids - pids).size.should == 1
    end

    it "all children die, should update list" do
      start_ok_process(C.p3.merge(:monitor_children => {}, :children_update_period => Eye::SystemResources::cache.expire + 1))
      @process.watchers.keys.should == [:check_alive, :check_identity, :check_children]

      sleep 5 # ensure that children are found

      #p @process.children
      master_pid = @process.pid
      pids = @process.children.keys.sort

      # one of the child is just die
      Eye::System.execute("kill -HUP #{master_pid}")

      # sleep enought for update list
      sleep (Eye::SystemResources::cache.expire * 2 + 2).seconds

      new_pids = @process.children.keys.sort

      master_pid.should == @process.pid
      new_pids.size.should == 3
      (pids - new_pids).should == pids
      (new_pids - pids).should == new_pids
    end

    it "when process stops, children are cleaned up" do
      start_ok_process(C.p3.merge(:monitor_children => {}, :children_update_period => Eye::SystemResources::cache.expire + 1))
      sleep 5 # ensure that children are found

      pid = @process.pid
      @process.watchers.keys.should == [:check_alive, :check_identity, :check_children]
      @process.children.size.should == 3

      @process.stop
      sleep 2
      @process.watchers.keys.should == []
      @process.children.size.should == 0

      Eye::System.pid_alive?(pid).should == false
    end

  end

  describe "add_or_update_children" do
    before :each do
      start_ok_process(C.p1.merge(:monitor_children => {}))
    end

    it "add new children, update && remove" do
      stub(Eye::SystemResources).children(@process.pid){ [3,4,5] }
      @process.add_or_update_children
      @process.children.keys.sort.should == [3,4,5]

      stub(Eye::SystemResources).children(@process.pid){ [3,5,6] }
      @process.add_or_update_children
      @process.children.keys.sort.should == [3,5,6]

      stub(Eye::SystemResources).children(@process.pid){ [3,5] }
      @process.add_or_update_children
      @process.children.keys.sort.should == [3,5]

      stub(Eye::SystemResources).children(@process.pid){ [6,7] }
      @process.add_or_update_children
      @process.children.keys.sort.should == [6,7]

      @process.remove_children
      @process.children.should == {}
    end
  end

end
