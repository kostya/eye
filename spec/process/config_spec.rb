# -*- encoding : utf-8 -*-
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
  
end
