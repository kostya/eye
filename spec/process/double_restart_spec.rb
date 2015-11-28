require File.dirname(__FILE__) + '/../spec_helper'

describe Eye::Process do
  before :each do
    @process = process(C.p1)
  end

  it "should not double restarts if auto restart" do
    @process.schedule :command => :restart, :reason => "bounded memory"
    @process.schedule :command => :restart, :reason => "bounded cpu"

    sleep 3

    @process.states_history.count { |c| c[:state] == :restarting }.should == 1
  end

  it "should double restart if second is by hands" do
    @process.schedule :command => :restart, :reason => "bounded memory"
    @process.send_call(:command => :restart)

    sleep 3

    @process.states_history.count { |c| c[:state] == :restarting }.should == 2
  end

  it "double restart by hands should pass both" do
    @process.send_call(:command => :restart)
    @process.send_call(:command => :restart)

    sleep 3

    @process.states_history.count { |c| c[:state] == :restarting }.should == 2
  end

  it "triple restart by hands should pass only 2" do
    @process.send_call(:command => :restart)
    @process.send_call(:command => :restart)
    @process.send_call(:command => :restart)

    sleep 6

    @process.states_history.count { |c| c[:state] == :restarting }.should == 2
  end

end
