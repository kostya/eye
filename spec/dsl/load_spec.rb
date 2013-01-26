require File.dirname(__FILE__) + '/../spec_helper'

describe "Subfolder load spec" do

  it "should load file with full_path" do
    f = fixture("dsl/subfolder1/proc1.rb")
    conf = <<-E
      Eye.load("#{f}")
      Eye.application("bla") do        
        proc1(self, "e1")
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:name => "bla", :groups=>{
      "__default__"=>{:name => "__default__", :application => "bla", :processes=>{
        "e1"=>{:pid_file=>"e1.pid", :application=>"bla", :group=>"__default__", :name=>"e1"}}}}}}    
  end

  it "file loaded, but proc not exists in it" do
    f = fixture("dsl/subfolder1/proc1.rb")
    conf = <<-E
      Eye.load("#{f}")
      Eye.application("bla") do        
        proc55(self, "e1")
      end
    E
    expect{Eye::Dsl.load(conf)}.to raise_error(NoMethodError)
  end

  it "subfolder2" do
    file = fixture('dsl/subfolder2.eye')
    Eye::Dsl.load(nil, file).should == {
      "subfolder" => {:name => "subfolder", :working_dir=>"/tmp", :groups=>{
        "__default__"=>{:name => "__default__", :application => "subfolder", :working_dir=>"/tmp", :processes=>{
          "e2"=>{:working_dir=>"/tmp", :pid_file=>"e2.pid2", :application=>"subfolder", :group=>"__default__", :name=>"e2"}, 
          "e3"=>{:working_dir=>"/tmp", :pid_file=>"e3.pid3", :application=>"subfolder", :group=>"__default__", :name=>"e3"}}}}}}
  end

  it "subfolder3" do
    file = fixture('dsl/subfolder3.eye')
    Eye::Dsl.load(nil, file).should == {
      "subfolder" => {:name => "subfolder", :working_dir=>"/tmp", :groups=>{
        "__default__"=>{:name => "__default__", :application => "subfolder", :working_dir=>"/tmp", :processes=>{
          "e1"=>{:working_dir=>"/tmp", :pid_file=>"e1.pid4", :application=>"subfolder", :group=>"__default__", :name=>"e1"}, 
          "e2"=>{:working_dir=>"/tmp", :pid_file=>"e2.pid5", :application=>"subfolder", :group=>"__default__", :name=>"e2"}}}}}}
  end

end