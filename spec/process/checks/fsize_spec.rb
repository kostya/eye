require File.dirname(__FILE__) + '/../../spec_helper'

describe "Check FSize" do
  before :each do
    @c = C.p1.merge(
      :checks => C.check_fsize(:times => 3)
    )
  end

  it "should start periodical watcher" do
    start_ok_process(@c)

    @process.watchers.keys.should == [:check_alive, :check_identity, :check_fsize]

    @process.stop

    # after process stop should remove watcher
    @process.watchers.keys.should == []
  end

end

