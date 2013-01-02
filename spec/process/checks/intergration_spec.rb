require File.dirname(__FILE__) + '/../../spec_helper'

describe "Process Integration checks" do
  before :each do
    @c = C.p1.merge(
      :checks => join(C.check_cpu, C.check_mem, C.check_ctime, C.check_http)
    )

    FakeWeb.register_uri(:get, "http://localhost:3000/bla", :body => "Somebody OK")
  end

  it "should start periodical watcher" do
    start_ok_process(@c)

    @process.watchers.keys.should == [:check_alive, :check_cpu, :check_memory, :check_ctime, :check_http]

    @process.stop

    # after process stop should remove watcher
    @process.watchers.keys.should == []
  end

  it "with nochecks, should not add watcher" do
    @c.merge!(:nochecks => {:memory => 1, :cpu => 1})
    start_ok_process(@c)

    @process.watchers.keys.should == [:check_alive, :check_ctime, :check_http]

    @process.stop

    # after process stop should remove watcher
    @process.watchers.keys.should == []
  end

  it "intergration" do
    start_ok_process(@c)

    dont_allow(@process).queue(:restart)

    # should not happens anything
    sleep 10
  end

end
