# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Process::Config" do
  before :each do
    @p = Eye::Process.new({:pid_file => '/tmp/1.pid', :start_command => "a"})
  end

  it "should use throught [], c" do
    @p[:pid_file].should == "/tmp/1.pid"
    @p[:pid_file_ex].should == "/tmp/1.pid"
    @p[:checks].should == {}
  end

  it "c interface" do
    @p.c(:pid_file).should == "/tmp/1.pid"
  end
  
end
