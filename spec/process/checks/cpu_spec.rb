require File.dirname(__FILE__) + '/../../spec_helper'

describe "Process Cpu check" do

  before :each do
    @c = C.p1.merge(
      :checks => C.check_cpu
    )
  end

  it "should start periodical watcher" do
    start_ok_process(@c)

    @process.watchers.keys.should == [:check_alive, :check_identity, :check_cpu]

    @process.stop

    # after process stop should remove watcher
    @process.watchers.keys.should == []
  end

  describe "1 times" do
    before :each do
      @check = {:cpu => {:type => :cpu, :every => 2, :below => 10, :times => 1}}
    end

    it "when memory exceed limit process should restart" do
      start_ok_process(@c.merge(:checks => @check))

      stub(Eye::SystemResources).cpu(@process.pid){ 5 }

      sleep 3

      stub(Eye::SystemResources).cpu(@process.pid){ 20 }
      mock(@process).schedule(:restart, anything)

      sleep 1
    end

    it "else should not restart" do
      start_ok_process(@c.merge(:checks => @check))

      stub(Eye::SystemResources).cpu(@process.pid){ 5 }

      sleep 3

      stub(Eye::SystemResources).cpu(@process.pid){ 7 }
      dont_allow(@process).schedule(:restart)

      sleep 1
    end
  end

  describe "3 times" do
    before :each do
      @check = {:cpu => {:type => :cpu, :every => 2, :below => 10, :times => 3}}
    end

    it "when memory exceed limit process should restart" do
      start_ok_process(@c.merge(:checks => @check))
      stub(Eye::SystemResources).cpu(@process.pid){ 5 }

      sleep 3

      stub(Eye::SystemResources).cpu(@process.pid){ 15 }
      mock(@process).schedule(:restart, anything)

      sleep 6
    end

    it "else should not restart" do
      start_ok_process(@c.merge(:checks => @check))
      stub(Eye::SystemResources).cpu(@process.pid){ 5 }

      sleep 3

      stub(Eye::SystemResources).cpu(@process.pid){ 7 }
      dont_allow(@process).schedule(:restart)

      sleep 6
    end
  end

  describe "3 times" do
    before :each do
      @check = {:cpu => {:type => :cpu, :every => 2, :below => 10, :times => [3,5]}}
    end

    it "when memory exceed limit process should restart" do
      start_ok_process(@c.merge(:checks => @check))
      stub(Eye::SystemResources).cpu(@process.pid){ 5 }

      sleep 5

      stub(Eye::SystemResources).cpu(@process.pid){ 15 }
      mock(@process).schedule(:restart, anything)

      sleep 6
    end

    it "else should not restart" do
      start_ok_process(@c.merge(:checks => @check))
      stub(Eye::SystemResources).cpu(@process.pid){ 5 }

      sleep 5

      stub(Eye::SystemResources).cpu(@process.pid){ 7 }
      dont_allow(@process).schedule(:restart)

      sleep 6
    end
  end

end
