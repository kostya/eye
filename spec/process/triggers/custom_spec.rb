require File.dirname(__FILE__) + '/../../spec_helper'

describe "Trigger Custom" do
  describe "delete file" do
    before :each do
      @c = Eye::Controller.new
      r = @c.load(fixture("dsl/custom_trigger1.eye"))
      sleep 5
      @process = @c.process_by_name("1")
      @filename = @process[:working_dir] + "/1.tmp"
    end

    it "should delete file when stop" do
      File.open(@filename, 'w'){ |f| f.write "aaa" }
      File.exists?(@filename).should == true
      @process.stop
      File.exists?(@filename).should == false
    end
  end
end