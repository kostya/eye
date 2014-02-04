require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Process::Config" do

  it "should use throught [], c" do
    @p = Eye::Process.new({:pid_file => '1.pid', :start_command => "a", :working_dir => "/tmp"})
    @p[:pid_file].should == "1.pid"
    @p[:pid_file_ex].should == "/tmp/1.pid"
    @p[:checks].should == {}
  end

  it "c interface" do
    @p = Eye::Process.new({:pid_file => '/tmp/1.pid', :start_command => "a"})
    @p.c(:pid_file_ex).should == "/tmp/1.pid"
  end

  it "should expand stdout" do
    @p = Eye::Process.new({:working_dir => "/tmp", :stdout => '1.log', :start_command => "a", :pid_file => '/tmp/1.pid'})
    @p[:stdout].should == "/tmp/1.log"
  end

  it "check and triggers should {} if empty" do
    @p = Eye::Process.new({:working_dir => "/tmp", :stdout => '1.log', :start_command => "a", :pid_file => '/tmp/1.pid', :triggers => {}})
    @p[:checks].should == {}
    @p[:triggers].should == {:flapping => {:type=>:flapping, :times=>10, :within=>10}}
  end

  it "if trigger setted, no rewrite" do
    @p = Eye::Process.new({:working_dir => "/tmp", :stdout => '1.log', :start_command => "a", :pid_file => '/tmp/1.pid', :triggers => {:flapping => {:type=>:flapping, :times=>100, :within=>100}}})
    @p[:triggers].should == {:flapping => {:type=>:flapping, :times=>100, :within=>100}}
  end

  it "clear_pid default" do
    @p = Eye::Process.new({:pid_file => '/tmp/1.pid'})
    @p[:clear_pid].should == true
  end

  describe "control_pid?" do
    it "if daemonize than true" do
      @p = Eye::Process.new({:pid_file => '/tmp/1.pid', :daemonize => true})
      @p.control_pid?.should == true
    end

    it "if not daemonize than false" do
      @p = Eye::Process.new({:pid_file => '/tmp/1.pid'})
      @p.control_pid?.should == false
    end
  end

  describe ":children_update_period" do
    it "should set default" do
      @p = Eye::Process.new({:pid_file => '/tmp/1.pid'})
      @p[:children_update_period].should == 30.seconds
    end

    it "should set from global options" do
      @p = Eye::Process.new({:pid_file => '/tmp/1.pid', :children_update_period => 11.seconds})
      @p[:children_update_period].should == 11.seconds
    end

    it "should set from monitor_children sub options" do
      @p = Eye::Process.new({:pid_file => '/tmp/1.pid', :monitor_children => {:children_update_period => 12.seconds}})
      @p[:children_update_period].should == 12.seconds
    end

    it "should set from monitor_children sub options" do
      @p = Eye::Process.new({:pid_file => '/tmp/1.pid', :children_update_period => 11.seconds, :monitor_children => {:children_update_period => 12.seconds}})
      @p[:children_update_period].should == 12.seconds
    end

  end

end
