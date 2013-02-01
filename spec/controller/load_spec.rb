require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Controller::Load" do
  subject{ Eye::Controller.new }

  it "blank" do
    subject.load.should == {:error => true, :message => "config file '' not found!"}
  end

  it "not exists file" do
    subject.load("/asdf/asd/fasd/fas/df/sfd").should == {:error => true, :message => "config file '/asdf/asd/fasd/fas/df/sfd' not found!"}
  end

  it "load 1 app" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}
  end

  it "load correctly application, groups for full_names processes" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)

    p1 = subject.process_by_name('p1')
    p1[:application].should == 'app1'
    p1[:group].should == 'gr1'
    p1.name.should == 'p1'
    p1.full_name.should == 'app1:gr1:p1'

    gr1 = subject.group_by_name 'gr1'
    gr1.full_name.should == 'app1:gr1'

    g4 = subject.process_by_name('g4')
    g4[:application].should == 'app1'
    g4[:group].should == '__default__'
    g4.name.should == 'g4'
    g4.full_name.should == 'app1:g4'
  end

  it "load + 1new app" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}

    subject.load(fixture("dsl/load2.eye")).should include(error: false)

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}, 
      "app3"=>{"__default__"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "load 1 changed app" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.load(fixture("dsl/load2.eye")).should include(error: false)

    p = subject.process_by_name('e1')
    p[:daemonize].should == false

    proxy(p).schedule :update_config, anything
    dont_allow(p).schedule :monitor

    subject.load(fixture("dsl/load3.eye")).should include(error: false)

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}, 
      "app3"=>{"wow"=>{"e1"=>"/tmp/app3-e1.pid"}}}

    sleep 0.1
    p2 = subject.process_by_name('e1')
    p2[:daemonize].should == true

    p.object_id.should == p2.object_id
  end

  it "load -> delete -> load" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.load(fixture("dsl/load2.eye")).should include(error: false)
    subject.command(:delete, 'app3')
    subject.load(fixture("dsl/load3.eye")).should include(error: false)

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}, 
      "app3"=>{"wow"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "load + 1 app, and pid_file crossed" do
    subject.load(fixture("dsl/load2.eye")).should include(error: false)
    subject.load(fixture("dsl/load4.eye")).should include(:error => true, :message => "dublicate pid_files: {\"/tmp/app3-e1.pid\"=>2}")

    subject.short_tree.should == {
      "app3"=>{"__default__"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "check syntax" do
    subject.load(fixture("dsl/load2.eye")).should include(error: false)
    subject.check(fixture("dsl/load4.eye")).should include(:error => true, :message => "dublicate pid_files: {\"/tmp/app3-e1.pid\"=>2}")
  end

  it "check explain" do
    res = subject.explain(fixture("dsl/load2.eye"))
    res[:error].should == false
    res[:config].is_a?(Hash).should == true
  end

  it "process and groups disappears" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.load(fixture("dsl/load5.eye")).should include(error: false)

    group_actors = Celluloid::Actor.all.select{|c| c.class == Eye::Group }
    process_actors = Celluloid::Actor.all.select{|c| c.class == Eye::Process }

    subject.short_tree.should == {
      "app1"=>{"gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}

    group_actors.map{|a| a.name}.sort.should == %w{__default__ gr1}
    process_actors.map{|a| a.name}.sort.should == %w{p1 z1}
  end

  it "swap groups" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.load(fixture("dsl/load6.eye")).should include(error: false)

    subject.short_tree.should == {
      "app1" => {
        "gr2"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr1"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}
  end

  it "two configs with same pids (should validate final config)" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.load(fixture("dsl/load2*.eye")).should == {:error => true, :message=>"dublicate pid_files: {\"/tmp/app3-e1.pid\"=>2}"}    
  end

  it "two configs with same pids (should validate final config)" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    subject.load(fixture("dsl/load2.eye")).should include(error: false)
    subject.load(fixture("dsl/load2_*.eye")).should == {:error => true, :message=>"dublicate pid_files: {\"/tmp/app3-e1.pid\"=>2}"}
  end

  it "dups of pid_files, but they different with expand" do
    subject.load(fixture("dsl/load2_dup2.eye")).should include(error: false)
  end

  it "dups of names but in different scopes" do
    subject.load(fixture("dsl/load_dup_ex_names.eye")).should include(error: false)
  end

  describe "load logger" do
    it "load logger" do
      subject.load(fixture("dsl/load_logger.eye")).should include(error: false)
      Eye::Logger.dev.should == "/tmp/1.log"
      
      # return global logger
      set_glogger
    end

    it "set logger when load multiple configs" do
      subject.load(fixture("dsl/load_logger{,2}.eye")).should include(error: false)
      Eye::Logger.dev.should == "/tmp/1.log"
      
      # return global logger
      set_glogger
    end
  end


  it "load folder" do
    subject.load(fixture("dsl/load_folder/")).should include(error: false)
    subject.short_tree.should == {       
      "app3" => {"wow"=>{"e1"=>"/tmp/app3-e1.pid"}},
      "app4" => {"__default__"=>{"e2"=>"/tmp/app4-e2.pid"}}
    }
  end
  
  it "load folder with error" do
    subject.load(fixture("dsl/load_error_folder/")).should include(error: true)
  end

  it "load files by mask" do
    subject.load(fixture("dsl/load_folder/*.eye")).should include(error: false)
    subject.short_tree.should == {       
      "app3" => {"wow"=>{"e1"=>"/tmp/app3-e1.pid"}},
      "app4" => {"__default__"=>{"e2"=>"/tmp/app4-e2.pid"}}
    }
  end
  
  it "load files by mask with error" do
    subject.load(fixture("dsl/load_error_folder/*.eye")).should include(error: true)
  end

  it "load not files with mask" do
    subject.load(fixture("dsl/load_folder/*.bla")).should include(error: true) 
  end

  it "bad mask" do
    subject.load(" asdf asdf afd d").should == {:error => true, :message => "config file ' asdf asdf afd d' not found!"}
  end

  it "group update it settings" do
    subject.load(fixture("dsl/load.eye")).should include(error: false)
    app = subject.application_by_name('app1')
    gr = subject.group_by_name('gr2')
    gr.config[:chain].should == {:restart => {:grace=>0.5, :action=>:restart}, :start => {:grace=>0.5, :action=>:start}}

    subject.load(fixture("dsl/load6.eye")).should include(error: false)
    sleep 1

    gr.config[:chain].should == {:restart => {:grace=>1.0, :action=>:restart}, :start => {:grace=>1.0, :action=>:start}}
  end

  it "raised load" do
    subject.load(fixture("dsl/load_error.eye")).should == {error: true, message: "No such file or directory - /asd/fasd/fas/df/asd/fas/df/d"}
  end

  describe "synchronize groups" do
    it "correctly schedule monitor for groups and processes" do
      subject.load(fixture("dsl/load_int.eye")).should include(error: false)
      sleep 0.5

      p0 = subject.process_by_name 'p0'
      p1 = subject.process_by_name 'p1'
      p2 = subject.process_by_name 'p2'
      gr1 = subject.group_by_name 'gr1'
      gr_ = subject.group_by_name '__default__'

      p0.schedule_history.states.should == [:monitor]
      p1.schedule_history.states.should == [:monitor]
      p2.schedule_history.states.should == [:monitor]
      gr1.schedule_history.states.should == [:monitor]
      gr_.schedule_history.states.should == [:monitor]

      subject.load(fixture("dsl/load_int2.eye")).should include(error: false)
      sleep 0.5

      p1.alive?.should == false
      p0.alive?.should == false

      p01 = subject.process_by_name 'p0-1'
      p4 = subject.process_by_name 'p4'
      p5 = subject.process_by_name 'p5'
      gr2 = subject.group_by_name 'gr2'

      p2.schedule_history.states.should == [:monitor, :update_config]
      gr1.schedule_history.states.should == [:monitor, :update_config]
      gr_.schedule_history.states.should == [:monitor, :update_config]

      p01.schedule_history.states.should == [:monitor]
      p4.schedule_history.states.should == [:monitor]
      p5.schedule_history.states.should == [:monitor]
      gr2.schedule_history.states.should == [:monitor]
    end
  end

end