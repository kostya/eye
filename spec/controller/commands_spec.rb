require File.dirname(__FILE__) + '/../spec_helper'

describe "comamnd spec" do
  subject{ c = Eye::Controller.new; c.load(fixture("dsl/load.eye")); c }

  before :each do
    @apps = subject.applications

    @app1 = @apps.first
    @app2 = @apps.last

    @gr1 = @app1.groups[0]
    @gr2 = @app1.groups[1]
    @gr3 = @app1.groups[2]
    @gr4 = @app2.groups[0]

    @p1 = @gr1.processes[0]
    @p2 = @gr1.processes[1]
    @p3 = @gr2.processes[0]
    @p4 = @gr3.processes[0]
    @p5 = @gr3.processes[1]
    @p6 = @gr4.processes[0]
  end

  describe "remove objects" do
    it "remove app" do
      subject.remove_object_from_tree(@app2)
      subject.applications.size.should == 1
      subject.applications.first.should == @app1
    end

    it "remove group" do
      subject.remove_object_from_tree(@gr1)
      @app1.groups.should_not include(@gr1)

      subject.remove_object_from_tree(@gr2)
      @app1.groups.should_not include(@gr2)

      subject.remove_object_from_tree(@gr3)
      @app1.groups.should_not include(@gr3)

      @app1.groups.should be_empty
    end

    it "remove process" do
      subject.remove_object_from_tree(@p1)
      @gr1.processes.should_not include(@p1)

      subject.remove_object_from_tree(@p2)
      @gr1.processes.should_not include(@p2)

      @gr1.processes.should be_empty
    end
  end

  it "unknown" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.command(:st33art, "2341234").should == :unknown_command
  end

  it "ping" do
    subject.command(:ping).should == :pong
  end

  it "quit" do
    mock(Eye::System).send_signal($$, :TERM)
    mock(Eye::System).send_signal($$, :KILL)
    subject.command(:quit)
  end

  describe "send_command" do
    it "command load" do
      res = subject.command(:load, fixture("dsl/load.eye"))
      res.class.should == Hash
    end

    it "nothing" do
      subject.load(fixture("dsl/load.eye")).should_be_ok
      subject.send_command(:start, "2341234").should == {:result => []}
    end

    it "unknown" do
      subject.load(fixture("dsl/load.eye")).should_be_ok
      subject.send_command(:st33art, "2341234").should == {:result=>[]}
    end

    [:start, :stop, :restart, :unmonitor].each do |cmd|
      it "should send_command #{cmd}" do
        sleep 0.3
        any_instance_of(Eye::Process) do |p|
          dont_allow(p).send_command(cmd)
        end

        mock(@p1).send_command(cmd)

        subject.send_command cmd, "p1", :some_flag => true
      end
    end

    it "unmonitor group" do
      sleep 0.5
      cmd = :unmonitor

      subject.send_command cmd, "gr1"
      sleep 0.5

      @p1.schedule_history.states.should == [:monitor, :unmonitor]
      @p2.schedule_history.states.should == [:monitor, :unmonitor]
      @p3.schedule_history.states.should == [:monitor]
    end

    it "stop group with skip_group_action for @p2" do
      sleep 0.5
      cmd = :stop

      stub(@p2).skip_group_action?(:stop) { true }

      subject.send_command cmd, "gr1"
      sleep 0.5

      @p1.schedule_history.states.should == [:monitor, :stop]
      @p2.schedule_history.states.should == [:monitor]
      @p3.schedule_history.states.should == [:monitor]
    end

    it "delete obj" do
      sleep 0.5
      any_instance_of(Eye::Process) do |p|
        dont_allow(p).send_command(:delete)
      end

      mock(@p1).send_command(:delete)
      subject.send_command :delete, "p1"

      subject.all_processes.should_not include(@p1)
      subject.all_processes.should include(@p2)
    end
  end

end