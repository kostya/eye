require File.dirname(__FILE__) + '/../spec_helper'

describe "StopOnDelete behaviour" do
  before :each do
    start_controller do
      @controller.load_erb(fixture("dsl/integration_sor.erb"))
    end
  end

  after :each do
    stop_controller
  end

  it "delete process => stop process" do
    @controller.send_command(:delete, "sample1")
    sleep 7 # while

    @controller.all_processes.map(&:name).sort.should == %w{forking sample2}
    @controller.all_groups.map(&:name).sort.should == %w{__default__ samples}

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true

    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false
  end

  it "delete application => stop group proceses" do
    @controller.send_command(:delete, "samples").should == {:result => ["int:samples"]}
    sleep 7 # while

    @controller.all_processes.should == [@p3]
    @controller.all_groups.map(&:name).should == ['__default__']

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == true

    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false

    # noone up this
    sleep 2
    Eye::System.pid_alive?(@old_pid1).should == false
  end

  it "delete application => stop all proceses" do
    @controller.send_command(:delete, "int")
    sleep 8 # while

    @controller.all_processes.should == []
    @controller.all_groups.should == []
    @controller.applications.should == []

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == false

    sleep 1
    Eye::System.pid_alive?(@old_pid1).should == false

    actors = Celluloid::Actor.all.map(&:class)
    actors.should_not include(Eye::Utils::CelluloidChain)
    actors.should_not include(Eye::Process)
    actors.should_not include(Eye::Group)
    actors.should_not include(Eye::Application)
    actors.should_not include(Eye::Checker::Memory)
  end

  it "load config when 1 process deleted, it should stopped" do
    @controller.load_erb(fixture("dsl/integration_sor2.erb"))

    sleep 10

    procs = @controller.all_processes
    @p1_ = procs.detect{|c| c.name == 'sample1'}
    @p2_ = procs.detect{|c| c.name == 'sample2'}
    @p3_ = procs.detect{|c| c.name == 'sample3'}

    @p1_.object_id.should == @p1.object_id
    @p2_.object_id.should == @p2.object_id
    @p3_.state_name.should == :up

    @p1_.pid.should == @old_pid1
    @p2_.pid.should == @old_pid2

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == false

    @p3.alive?.should == false
    @controller.all_processes.map{|c| c.name}.sort.should == %w{sample1 sample2 sample3}
  end

  it "load another config, with same processes but changed names" do
    @controller.load_erb(fixture("dsl/integration_sor3.erb"))

    sleep 15

    # @p1, @p2 recreates
    # @p3 the same

    procs = @controller.all_processes
    @p1_ = procs.detect{|c| c.name == 'sample1_'}
    @p2_ = procs.detect{|c| c.name == 'sample2_'}
    @p3_ = procs.detect{|c| c.name == 'forking'}

    @p3.object_id.should == @p3_.object_id
    @p1.alive?.should == false
    @p1_.alive?.should == true

    @p2.alive?.should == false
    @p2_.alive?.should == true

    @p1_.pid.should_not == @old_pid1
    @p2_.pid.should_not == @old_pid2
    @p3_.pid.should == @old_pid3

    @p1_.state_name.should == :up
    @p2_.state_name.should == :up
    @p3_.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == true

    Eye::System.pid_alive?(@p1_.pid).should == true
    Eye::System.pid_alive?(@p2_.pid).should == true
  end

end
