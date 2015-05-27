require File.dirname(__FILE__) + '/../spec_helper'

describe Eye::Process do
  before :each do
    @process = process(C.p1)
  end

  it "should not double restarts if auto restart" do
    pending
    @process.schedule :restart, Eye::Reason.new("bounded memory")
    @process.schedule :restart, Eye::Reason.new("bounded cpu")

    sleep 3

    @process.states_history.count { |c| c[:state] == :restarting }.should == 1
  end

  it "should double restart if second is by hands" do
    @process.schedule :restart, Eye::Reason.new("bounded memory")
    @process.send_command(:restart)

    sleep 3

    @process.states_history.count { |c| c[:state] == :restarting }.should == 2
  end
end
