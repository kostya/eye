require File.dirname(__FILE__) + '/../../spec_helper'

describe "Eye::Checker::ChildrenMemory" do
  it "should not restart because all is ok" do
    @process = start_ok_process(C.p1.merge(:checks => C.check_children_memory(:below => 50), :monitor_children => {}))

    3.times { @pids << Eye::System.daemonize("sleep 10")[:pid] }
    stub(Eye::SystemResources).children(@process.pid){ @pids }
    @process.add_children

    stub(Eye::SystemResources).memory(anything) { 1 }

    dont_allow(@process).schedule(:restart, anything)

    sleep 5
  end

  it "should restart with strategy :restart" do
    @process = start_ok_process(C.p1.merge(:checks => C.check_children_memory(:below => 50), :monitor_children => {}))

    10.times { @pids << Eye::System.daemonize("sleep 10")[:pid] }
    stub(Eye::SystemResources).children(@process.pid){ @pids }
    @process.add_children

    stub(Eye::SystemResources).memory(anything) { 11 }
    mock(@process).schedule(:restart, anything)

    sleep 5
  end
end
