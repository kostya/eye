require File.dirname(__FILE__) + '/../../spec_helper'

describe "Process Tail Log" do
  before :each do
    @c = C.p1.merge(
      :checks => C.check_tail_log(:times => 2)
    )
  end

  it "should start periodical watcher" do
    start_ok_process(@c)

    @process.watchers.keys.should == [:check_alive, :check_tail_log]

    @process.stop

    # after process stop should remove watcher
    @process.watchers.keys.should == []
  end

  it "if log tailing should restart" do
    start_ok_process(@c)
    @process.watchers.keys.should == [:check_alive, :check_tail_log]

    dont_allow(@process).queue(:restart)

    sleep 6
  end

  it "log stopped" do
    start_ok_process(@c)

    mock(@process).queue(:restart)

    sleep 3

    FileUtils.rm(C.p1[:stdout])

    sleep 5
  end

end

