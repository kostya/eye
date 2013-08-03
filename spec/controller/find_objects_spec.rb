require File.dirname(__FILE__) + '/../spec_helper'

describe "find_objects" do
  describe "simple matching" do
    subject{ new_controller(fixture("dsl/load.eye")) }

    it "1 process" do
      objs = subject.find_objects("p1")
      objs.class.should == Eye::Utils::AliveArray
      objs.map(&:full_name).sort.should == %w{app1:gr1:p1}
      objs.map(&:class).should == [Eye::Process]
    end

    it "1 group" do
      objs = subject.find_objects("gr2")
      objs.map(&:full_name).sort.should == %w{app1:gr2}
      objs.map(&:class).should == [Eye::Group]
    end

    it "1 app" do
      objs = subject.find_objects("app2")
      objs.map(&:full_name).sort.should == %w{app2}
      objs.map(&:class).should == [Eye::Application]
    end

    it "find * processes by mask" do
      objs = subject.find_objects("p*")
      objs.map(&:full_name).sort.should == %w{app1:gr1:p1 app1:gr1:p2}
    end

    it "find * groups by mask" do
      objs = subject.find_objects("gr*")
      objs.map(&:full_name).sort.should == %w{app1:gr1 app1:gr2}
    end

    it "find * apps by mask" do
      objs = subject.find_objects("app*")
      objs.map(&:full_name).sort.should == %w{app1 app2}
    end

    it "find by ','" do
      objs = subject.find_objects("p1,p2")
      objs.map(&:full_name).sort.should == %w{app1:gr1:p1 app1:gr1:p2}
    end

    it "find by ',' with empty part" do
      objs = subject.find_objects("p1,")
      objs.map(&:full_name).sort.should == %w{app1:gr1:p1}
    end

    it "find by many params" do
      objs = subject.find_objects("p1", "p2")
      objs.map(&:full_name).sort.should == %w{app1:gr1:p1 app1:gr1:p2}
    end

    it "find * apps by mask" do
      objs = subject.find_objects("z*\n")
      objs.map(&:full_name).sort.should == %w{app2:z1}
    end

    it "'all', find all projects" do
      objs = subject.find_objects("all")
      objs.map(&:full_name).sort.should == %w{app1 app2}
    end

    it "'*', find all projects" do
      objs = subject.find_objects("*")
      objs.map(&:full_name).sort.should == %w{app1 app2}
    end

    it "nothing" do
      subject.find_objects("").should == []
      subject.find_objects("asdfasdf").should == []
      subject.find_objects("2").should == []
      subject.find_objects("pp").should == []
    end

    describe "submatching without * " do
      it "match by start symbols, apps" do
        objs = subject.find_objects("app")
        objs.map(&:full_name).sort.should == %w{app1 app2}
      end

      it "match by start symbols, groups" do
        objs = subject.find_objects("gr")
        objs.map(&:full_name).sort.should == %w{app1:gr1 app1:gr2}
      end

      it "match by start symbols, process" do
        objs = subject.find_objects("z")
        objs.map(&:full_name).sort.should == %w{app2:z1}
      end
    end

    describe "find by routes" do
      it "group" do
        objs = subject.find_objects("app1:gr2")
        objs.map(&:full_name).sort.should == %w{app1:gr2}
      end

      it "group + mask" do
        objs = subject.find_objects("app1:gr*")
        objs.map(&:full_name).sort.should == %w{app1:gr1 app1:gr2}
      end

      it "process" do
        objs = subject.find_objects("app1:gr2:q3")
        objs.map(&:full_name).sort.should == %w{app1:gr2:q3}
      end
    end

    describe "missing" do
      it "should not found" do
        subject.find_objects("app1:gr4").should == []
        subject.find_objects("gr:p").should == []
        subject.find_objects("pp1").should == []
        subject.find_objects("app1::").should == []
        subject.find_objects("app1:=").should == []
        subject.find_objects("* *").should == []
        subject.find_objects(",").should == []
      end
    end

    describe "match" do
      it "should match" do
        subject.match("gr*").should == ["app1:gr1", "app1:gr2"]
      end
    end
  end


  describe "dubls" do
    subject{ new_controller(fixture("dsl/load_dubls.eye")) }

    it "not found" do
      subject.find_objects("zu").should == []
    end

    it "found 2 processed" do
      objs = subject.find_objects("z*")
      objs.map(&:full_name).sort.should == %w{app2:gr1:z2 app2:z1}
    end

    it "find by gr1" do
      objs = subject.find_objects("gr1")
      objs.map(&:full_name).sort.should == %w{} # because from different apps
    end

    it "correct by gr*" do
      objs = subject.find_objects("gr*")
      objs.map(&:full_name).should == %w{}

      objs = subject.find_objects("app1:gr*")
      objs.map(&:full_name).should == %w{app1:gr1 app1:gr2 app1:gr2and}
    end

    it "correct process" do
      objs = subject.find_objects("gr1and")
      objs.map(&:full_name).sort.should == %w{app2:gr1:gr1and}
    end
  end

  describe "exactly matching" do
    subject{ new_controller(fixture("dsl/load_dubls.eye")) }

    it "find 1 process by short name" do
      objs = subject.find_objects("some")
      objs.class.should == Eye::Utils::AliveArray
      objs.map(&:full_name).sort.should == %w{app5:some}
    end

    it "find 1 process by short name" do
      objs = subject.find_objects("mu")
      objs.map(&:full_name).sort.should == %w{app5:gr7:mu}
    end

    it "find 1 process by full name" do
      objs = subject.find_objects("app5:some")
      objs.map(&:full_name).sort.should == %w{app5:some}
    end

    it "find 1 process by full name and mask" do
      objs = subject.find_objects("app*:some")
      objs.map(&:full_name).sort.should == %w{app5:some}
    end

    it "find 1 process by full name and mask" do
      objs = subject.find_objects("*some")
      objs.map(&:full_name).sort.should == %w{app5:some}
    end

    it "2 targets" do
      objs = subject.find_objects("some", "am")
      objs.map(&:full_name).sort.should == %w{app5:am app5:some}
    end

    it "2 targets with multi" do
      objs = subject.find_objects("some", "am*")
      objs.map(&:full_name).sort.should == %w{app5:am app5:am2 app5:some}
    end

    it "with group" do
      objs = subject.find_objects("some", "*gr7:mu")
      objs.map(&:full_name).sort.should == %w{app5:gr7:mu app5:some}
    end

    it "find multiple by not exactly match" do
      objs = subject.find_objects("som")
      objs.map(&:full_name).sort.should == %w{app5:some app5:some2 app5:some_name}
    end

    it "find multiple by exactly with *" do
      objs = subject.find_objects("some*")
      objs.map(&:full_name).sort.should == %w{app5:some app5:some2 app5:some_name}
    end

    it "find multiple by exactly with *" do
      objs = subject.find_objects("*some*")
      objs.map(&:full_name).sort.should == %w{app5:some app5:some2 app5:some_name}
    end

    it "in different apps" do
      objs = subject.find_objects("one")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "when exactly matched object and subobject" do
      objs = subject.find_objects("serv")
      objs.map(&:full_name).sort.should == %w{app5:serv}
    end
  end

  describe "Not allow objects from different apps" do
    subject{ new_controller(fixture("dsl/load_dubls2.eye")) }

    it "`admin` should not match anything" do
      objs = subject.find_objects("admin")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`zoo` should not match anything" do
      objs = subject.find_objects("zoo")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`e1` should not match anything" do
      objs = subject.find_objects("e1")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`koo` should match group" do
      objs = subject.find_objects("koo")
      objs.map(&:full_name).sort.should == %w{app2:koo}
    end

    it "`*admin` should not match anything" do
      objs = subject.find_objects("*admin")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`*zoo` should not match anything" do
      objs = subject.find_objects("*zoo")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`*e1` should not match anything" do
      objs = subject.find_objects("*e1")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`*:e1` should not match anything" do
      objs = subject.find_objects("*:e1")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`*p1` should not match anything" do
      objs = subject.find_objects("*p1")
      objs.map(&:full_name).sort.should == %w{}
    end

    it "`app1:admin` should match" do
      objs = subject.find_objects("app1:admin")
      objs.map(&:full_name).sort.should == %w{app1:admin}
    end

    it "multiple targets allowed" do
      objs = subject.find_objects("app1:admin", "app2:admin")
      objs.map(&:full_name).sort.should == %w{app1:admin app2:admin}
    end
  end
end