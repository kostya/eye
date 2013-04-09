require File.dirname(__FILE__) + '/../spec_helper'

describe "find_objects" do
  subject{ c = Eye::Controller.new; c.load(fixture("dsl/load.eye")); c }

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

  it "find by ','" do
    objs = subject.find_objects("p1,p2")
    objs.map{|c| c.class}.should == [Eye::Process, Eye::Process]
    objs.map{|c| c.name}.sort.should == %w{p1 p2}
  end

  it "find by many params" do
    objs = subject.find_objects("p1", "p2")
    objs.map{|c| c.class}.should == [Eye::Process, Eye::Process]
    objs.map{|c| c.name}.sort.should == %w{p1 p2}
  end

  it "find * apps by mask" do
    objs = subject.find_objects("z*\n")
    objs.map{|c| c.class}.should == [Eye::Process]
    objs.map{|c| c.name}.sort.should == %w{z1}
  end

  it "empty, find nothing" do
    subject.find_objects("").should == []
  end

  it "'all', find all projects" do
    objs = subject.find_objects("all")
    objs.map{|c| c.class}.should == [Eye::Application, Eye::Application]
    objs.map{|c| c.name}.sort.should == %w{app1 app2}
  end

  it "'*', find all projects" do
    objs = subject.find_objects("*")
    objs.map{|c| c.class}.should == [Eye::Application, Eye::Application]
    objs.map{|c| c.name}.sort.should == %w{app1 app2}
  end

  it "nothing" do
    subject.find_objects("asdfasdf").should == []
  end

  describe "submatching without * " do
    it "match by start symbols, apps" do
      objs = subject.find_objects("app")
      objs.map{|c| c.class}.should == [Eye::Application, Eye::Application]
      objs.map{|c| c.name}.sort.should == %w{app1 app2}
    end

    it "match by start symbols, groups" do
      objs = subject.find_objects("gr")
      objs.map{|c| c.class}.should == [Eye::Group, Eye::Group]
      objs.map{|c| c.name}.sort.should == %w{gr1 gr2}
    end

    it "match by start symbols, process" do
      objs = subject.find_objects("z")
      objs.map{|c| c.class}.should == [Eye::Process]
      objs.map{|c| c.name}.sort.should == %w{z1}
    end
  end

  describe "find by routes" do
    it "group" do
      objs = subject.find_objects("app1:gr2")
      obj = objs.first
      obj.class.should == Eye::Group
      obj.full_name.should == 'app1:gr2'
    end

    it "group + mask" do
      objs = subject.find_objects("app1:gr*")
      objs.map{|c| c.class}.should == [Eye::Group, Eye::Group]
      objs.map{|c| c.name}.sort.should == %w{gr1 gr2}
    end

    it "process" do
      objs = subject.find_objects("app1:gr2:q3")
      obj = objs.first
      obj.class.should == Eye::Process
      obj.full_name.should == 'app1:gr2:q3'
    end

    describe "dubls" do
      subject{ c = Eye::Controller.new; c.load(fixture("dsl/load_dubls.eye")); c }

      it "not found" do
        subject.find_objects("zu").should == []
      end

      it "found 2 processed" do
        objs = subject.find_objects("z*")
        objs.map{|c| c.class}.should == [Eye::Process, Eye::Process]
        objs.map{|c| c.name}.sort.should == %w{z1 z2}
      end

      it "find by gr1" do
        objs = subject.find_objects("gr1")
        objs.map{|c| c.class}.should == [Eye::Group, Eye::Group]
        objs.map{|c| c.full_name}.sort.should == %w{app1:gr1 app2:gr1}
      end

      it "correct by gr*" do
        objs = subject.find_objects("gr*")
        objs.map{|c| c.class}.should == [Eye::Group, Eye::Group, Eye::Group, Eye::Process]
        objs.map{|c| c.full_name}.should == %w{app1:gr1 app1:gr2 app2:gr1 app1:gr2and}
      end

      it "correct by gr1*" do
        objs = subject.find_objects("gr1*")
        objs.map{|c| c.class}.should == [Eye::Group, Eye::Group]
        objs.map{|c| c.full_name}.sort.should == %w{app1:gr1 app2:gr1}
      end

      it "correct process" do
        objs = subject.find_objects("gr1and")
        objs.map{|c| c.class}.should == [Eye::Process]
        objs.map{|c| c.full_name}.sort.should == %w{app2:gr1:gr1and}
      end
    end
  end

  describe "missing" do
    it "should not found" do
      subject.find_objects("app1:gr4").should == []
      subject.find_objects("gr:p").should == []
      subject.find_objects("pp1").should == []
      subject.find_objects("app1::").should == []
      subject.find_objects("app1:=").should == []
    end
  end

  describe "match" do
    it "should match" do
      subject.match("gr*").should == ["app1:gr1", "app1:gr2"]
    end
  end

end