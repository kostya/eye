require File.dirname(__FILE__) + '/../../spec_helper'

describe "Check CTime" do
  before :each do
    @c = C.p1.merge(
      :checks => C.check_ctime(:times => 3)
    )
  end

  it "should start periodical watcher" do
    start_ok_process(@c)

    @process.watchers.keys.should == [:check_alive, :check_identity, :check_ctime]
    sbj = @process.watchers[:check_ctime][:subject]
    sbj.file.should == "#{C.sample_dir}/#{C.log_name}"

    @process.stop

    # after process stop should remove watcher
    @process.watchers.keys.should == []
  end

  it "if ctime changes should_not restart" do
    start_ok_process(@c)
    @process.watchers.keys.should == [:check_alive, :check_identity, :check_ctime]

    dont_allow(@process).schedule(:restart)

    sleep 6
  end

  it "if ctime not changed should restart" do
    start_ok_process(@c)

    mock(@process).schedule(:restart, anything)

    sleep 3

    FileUtils.rm(C.p1[:stdout])

    sleep 5
  end

end

