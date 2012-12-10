require File.dirname(__FILE__) + '/../spec_helper'

describe "find_objects" do
  subject{ c = controller_new; c.load(fixture("dsl/load.eye")); c }

  it "1 process" do
    objs = subject.find_objects("p1")
    objs.map{|c| c.class}.should == [Eye::Process]
    objs.map{|c| c.name}.sort.should == %w{p1}
  end

  it "1 group" do
    objs = subject.find_objects("gr2")
    objs.map{|c| c.class}.should == [Eye::Group]
    objs.map{|c| c.name}.sort.should == %w{gr2}
  end

  it "1 app" do
    objs = subject.find_objects("app2")
    objs.map{|c| c.class}.should == [Eye::Application]
    objs.map{|c| c.name}.sort.should == %w{app2}
  end

  it "find * processes by mask" do
    objs = subject.find_objects("p*")
    objs.map{|c| c.class}.should == [Eye::Process, Eye::Process]
    objs.map{|c| c.name}.sort.should == %w{p1 p2}
  end

  it "find * groups by mask" do
    objs = subject.find_objects("gr*")
    objs.map{|c| c.class}.should == [Eye::Group, Eye::Group]
    objs.map{|c| c.name}.sort.should == %w{gr1 gr2}
  end

  it "find * apps by mask" do
    objs = subject.find_objects("app*")
    objs.map{|c| c.class}.should == [Eye::Application, Eye::Application]
    objs.map{|c| c.name}.sort.should == %w{app1 app2}
  end

  it "empty, find all projects" do
    objs = subject.find_objects("")
    objs.map{|c| c.class}.should == [Eye::Application, Eye::Application]
    objs.map{|c| c.name}.sort.should == %w{app1 app2}
  end

  it "nothing" do
    subject.find_objects("asdfasdf").should == []
  end

end