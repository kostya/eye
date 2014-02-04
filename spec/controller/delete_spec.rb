require File.dirname(__FILE__) + '/../spec_helper'

describe "Intergration Delete" do
  before :each do
    start_controller do
      @controller.load_erb(fixture("dsl/integration.erb"))
    end
  end

  after :each do
    stop_controller
  end

  it "delete group not monitoring anymore" do
    @controller.send_command(:delete, "samples").should == {:result => ["int:samples"]}
    sleep 7 # while

    @controller.all_processes.should == [@p3]
    @controller.all_groups.map(&:name).should == ['__default__']

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true

    Eye::System.send_signal(@old_pid1)
    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false

    # noone up this
    sleep 2
    Eye::System.pid_alive?(@old_pid1).should == false
  end

  it "delete process not monitoring anymore" do
    @controller.send_command(:delete, "sample1")
    sleep 7 # while

    @controller.all_processes.map(&:name).sort.should == %w{forking sample2}
    @controller.all_groups.map(&:name).sort.should == %w{__default__ samples}
    @controller.group_by_name('samples').processes.full_size.should == 1
    @controller.group_by_name('samples').processes.map(&:name).should == %w{sample2}

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true

    Eye::System.send_signal(@old_pid1)
    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false
  end

  it "delete application" do
    @p3.wait_for_condition(15, 0.3) { @p3.children.size == 3 }
    @pids += @p3.children.keys

    @controller.send_command(:delete, "int")
    sleep 7 # while

    @controller.all_processes.should == []
    @controller.all_groups.should == []
    @controller.applications.should == []

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true

    Eye::System.send_signal(@old_pid1)
    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false

    actors = Celluloid::Actor.all.map(&:class)
    actors.should_not include(Eye::Utils::CelluloidChain)
    actors.should_not include(Eye::Process)
    actors.should_not include(Eye::Group)
    actors.should_not include(Eye::Application)
    actors.should_not include(Eye::Checker::Memory)
  end

  it "delete by mask" do
    @controller.send_command(:delete, "sam*").should == {:result => ["int:samples"]}
    sleep 7 # while

    @controller.all_processes.should == [@p3]
    @controller.all_groups.map(&:name).should == ['__default__']

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true

    Eye::System.send_signal(@old_pid1)
    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false

    # noone up this
    sleep 2
    Eye::System.pid_alive?(@old_pid1).should == false
  end

end
