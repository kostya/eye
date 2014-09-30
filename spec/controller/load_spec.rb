require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Controller::Load" do
  subject{ Eye::Controller.new }

  it "command load exclusive" do
    futures = []
    should_spend(1.2, 0.2) do
      futures << subject.future.command('load', fixture("dsl/just_sleep.eye"))
      futures << subject.future.command('load', fixture("dsl/just_sleep.eye"))

      futures.map(&:value).map{ |r| r.values.first[:error] }.should == [false, false]
    end
  end

  it "should set :current_config as Eye::Config class" do
    subject.load(fixture("dsl/load.eye"))

    cfg = subject.current_config
    cfg.class.should == Eye::Config
    cfg.applications.should_not be_empty
    cfg.settings.should == {}
  end

  it "blank" do
    subject.load.should == {}
  end

  it "not exists file" do
    mock(subject).set_proc_line
    res = subject.load("/asdf/asd/fasd/fas/df/sfd")
    res["/asdf/asd/fasd/fas/df/sfd"][:error].should == true
    res["/asdf/asd/fasd/fas/df/sfd"][:message].should include("/asdf/asd/fasd/fas/df/sfd")
  end

  it "load 1 ok app" do
    res = subject.load(fixture("dsl/load.eye"))
    res.should_be_ok

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"},
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"},
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}

    res.only_value.should == { :error => false, :config => nil }
  end

  it "can accept options" do
    subject.load(fixture("dsl/load.eye"), :some => 1).should_be_ok
  end

  it "work fine throught command" do
    subject.command(:load, fixture("dsl/load.eye")).should_be_ok
  end

  it "load correctly application, groups for full_names processes" do
    subject.load(fixture("dsl/load.eye")).should_be_ok

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
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"},
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"},
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}

    subject.load(fixture("dsl/load2.eye")).should_be_ok

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"},
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"},
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}},
      "app3"=>{"__default__"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "load 1 changed app" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.load(fixture("dsl/load2.eye")).should_be_ok

    p = subject.process_by_name('e1')
    p[:daemonize].should == false

    proxy(p).schedule :update_config, is_a(Hash), is_a(Eye::Reason)
    dont_allow(p).schedule :monitor

    p.logger.prefix.should == 'app3:e1'

    subject.load(fixture("dsl/load3.eye")).should_be_ok

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
    p.logger.prefix.should == 'app3:wow:e1'
  end

  it "load -> delete -> load" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.load(fixture("dsl/load2.eye")).should_be_ok
    subject.command(:delete, 'app3')
    subject.load(fixture("dsl/load3.eye")).should_be_ok

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"},
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"},
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}},
      "app3"=>{"wow"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "load + 1 app, and pid_file crossed" do
    subject.load(fixture("dsl/load2.eye")).should_be_ok
    subject.load(fixture("dsl/load4.eye")).only_value.should include(:error => true, :message => "duplicate pid_files: {\"/tmp/app3-e1.pid\"=>2}")

    subject.short_tree.should == {
      "app3"=>{"__default__"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "check syntax" do
    subject.load(fixture("dsl/load2.eye")).should_be_ok
    subject.command(:check, fixture("dsl/load4.eye")).only_value.should include(:error => true, :message => "duplicate pid_files: {\"/tmp/app3-e1.pid\"=>2}")
  end

  it "check explain" do
    res = subject.command(:explain, fixture("dsl/load2.eye")).only_value
    res[:error].should == false
    res[:config].is_a?(Hash).should == true
  end

  it "process and groups disappears" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.group_by_name('gr1').processes.full_size.should == 2

    subject.load(fixture("dsl/load5.eye")).should_be_ok
    sleep 0.5

    group_actors = Celluloid::Actor.all.select{|c| c.class == Eye::Group }
    process_actors = Celluloid::Actor.all.select{|c| c.class == Eye::Process }

    subject.short_tree.should == {
      "app1"=>{"gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}

    group_actors.map{|a| a.name}.sort.should == %w{__default__ gr1}
    process_actors.map{|a| a.name}.sort.should == %w{p1 z1}

    subject.group_by_name('gr1').processes.full_size.should == 1

    # terminate 1 action
    subject.process_by_name('p1').terminate
    subject.info_data.should be_a(Hash)
  end

  it "swap groups" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.load(fixture("dsl/load6.eye")).should_be_ok

    subject.short_tree.should == {
      "app1" => {
        "gr2"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"},
        "gr1"=>{"q3"=>"/tmp/app1-gr2-q3.pid"},
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}
  end

  it "two configs with same pids (should validate final config)" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    res = subject.load(fixture("dsl/load2{,_dup_pid,_dup2}.eye"))
    res.ok_count.should == 2
    res.errors_count.should == 1
    res.only_match(/load2_dup_pid\.eye/).should include(:error => true, :message=>"duplicate pid_files: {\"/tmp/app3-e1.pid\"=>2}")
  end

  it "two configs with same pids (should validate final config)" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.load(fixture("dsl/load2.eye")).should_be_ok
    res = subject.load(fixture("dsl/load2_*.eye"))
    res.size.should > 1
    res.errors_count.should == 1
    res.only_match(/load2_dup_pid\.eye/).should include(:error => true, :message=>"duplicate pid_files: {\"/tmp/app3-e1.pid\"=>2}")
  end

  it "dups of pid_files, but they different with expand" do
    subject.load(fixture("dsl/load2_dup2.eye")).should_be_ok
  end

  it "dups of names but in different scopes" do
    subject.load(fixture("dsl/load_dup_ex_names.eye")).should_be_ok
  end

  it "processes with same names in different scopes should not create new processes on just update" do
    subject.load(fixture("dsl/load_dup_ex_names.eye")).should_be_ok
    p1 = subject.process_by_full_name('app1:p1:server')
    p2 = subject.process_by_full_name('app1:p2:server')

    subject.load(fixture("dsl/load_dup_ex_names2.eye")).should_be_ok

    t = subject.short_tree
    t['app1']['p1']['server'].should match('server1.pid')
    t['app1']['p2']['server'].should match('server2.pid')

    p12 = subject.process_by_full_name('app1:p1:server')
    p22 = subject.process_by_full_name('app1:p2:server')

    p12.object_id.should == p1.object_id
    p22.object_id.should == p2.object_id
  end

  it "same processes crossed in apps duplicate pids" do
    subject.load(fixture("dsl/load_dup_ex_names3.eye")).errors_count.should == 1
  end

  it "same processes crossed in apps" do
    subject.load(fixture("dsl/load_dup_ex_names4.eye")).should_be_ok
    p1 = subject.process_by_full_name('app1:gr:server')
    p2 = subject.process_by_full_name('app2:gr:server')
    p1.object_id.should_not == p2.object_id

    subject.load(fixture("dsl/load_dup_ex_names4.eye")).should_be_ok
    p12 = subject.process_by_full_name('app1:gr:server')
    p22 = subject.process_by_full_name('app2:gr:server')

    p12.object_id.should == p1.object_id
    p22.object_id.should == p2.object_id
  end

  it "order of applications and groups" do
    subject.load_content(<<-F)
      Eye.app(:app2) { }
      Eye.app(:app1) {
        process("p"){ pid_file "1" }
        group(:gr3){}
        group(:gr2){}
        group(:gr1){}
      }
    F

    subject.applications.map(&:name).should == %w{app1 app2}
    app = subject.applications[0]
    app.groups.map(&:name).should == %w{gr1 gr2 gr3 __default__}
  end

  describe "configs" do
    after(:each){ set_glogger }

    it "load logger" do
      subject.load(fixture("dsl/load_logger.eye")).should_be_ok
      Eye::Logger.dev.should == "/tmp/1.loG"
    end

    it "set logger when load multiple configs" do
      subject.load(fixture("dsl/load_logger{,2}.eye")).should_be_ok(2)
      Eye::Logger.dev.should == "/tmp/1.loG"
    end

    it "load logger with rotation" do
      subject.load_content(<<-S)
        Eye.config { logger "/tmp/1.log", 7, 10000 }
      S
      Eye::Logger.dev.should == "/tmp/1.log"
    end

    it "not set bad logger" do
      subject.load(fixture("dsl/load_logger.eye")).should_be_ok
      Eye::Logger.dev.should == "/tmp/1.loG"

      res = subject.load_content(<<-S)
        Eye.config { logger "/tmp/asdfasdf/sd/f/sdf/sd/f/sdf/s" }
      S

      Eye::Logger.dev.should == "/tmp/1.loG"
      subject.current_config.settings.should == {:logger=>["/tmp/1.loG"], :logger_level => 0}
    end

    it "not set bad logger" do
      subject.load_content(" Eye.config { logger 1 } ")
      Eye::Logger.dev.should be
    end

    it "set custom logger" do
      subject.load_content(" Eye.config { logger Logger.new('/tmp/eye_temp.log') } ")
      Eye::Logger.dev.instance_variable_get(:@logdev).filename.should == '/tmp/eye_temp.log'
    end

    it "should corrent load config section" do
      subject.load(fixture("dsl/configs/{1,2}.eye")).should_be_ok(2)
      Eye::Logger.dev.should == "/tmp/a.log"
      subject.current_config.settings.should == {:logger=>["/tmp/a.log"], :http=>{:enable=>true}}

      subject.load(fixture("dsl/configs/3.eye")).should_be_ok
      Eye::Logger.dev.should == "/tmp/a.log"
      subject.current_config.settings.should == {:logger=>["/tmp/a.log"], :http=>{:enable=>false}}

      subject.load(fixture("dsl/configs/4.eye")).should_be_ok
      Eye::Logger.dev.should == nil
      subject.current_config.settings.should == {:logger=>[nil], :http=>{:enable=>false}}

      subject.load(fixture("dsl/configs/2.eye")).should_be_ok
      Eye::Logger.dev.should == nil
      subject.current_config.settings.should == {:logger=>[nil], :http=>{:enable=>true}}
    end

    it "should load not settled config option" do
      subject.load(fixture("dsl/configs/5.eye")).should_be_ok
    end
  end


  it "load folder" do
    subject.load(fixture("dsl/load_folder/")).should_be_ok(2)
    subject.short_tree.should == {
      "app3" => {"wow"=>{"e1"=>"/tmp/app3-e1.pid"}},
      "app4" => {"__default__"=>{"e2"=>"/tmp/app4-e2.pid"}}
    }
  end

  it "load folder with error" do
    subject.load(fixture("dsl/load_error_folder/")).errors_count.should == 1
  end

  it "load files by mask" do
    subject.load(fixture("dsl/load_folder/*.eye")).should_be_ok(2)
    subject.short_tree.should == {
      "app3" => {"wow"=>{"e1"=>"/tmp/app3-e1.pid"}},
      "app4" => {"__default__"=>{"e2"=>"/tmp/app4-e2.pid"}}
    }
  end

  it "load files by mask with error" do
    subject.load(fixture("dsl/load_error_folder/*.eye")).errors_count.should == 1
  end

  it "load not files with mask" do
    subject.load(fixture("dsl/load_folder/*.bla")).errors_count.should == 1
  end

  it "bad mask" do
    s = " asdf asdf afd d"
    res = subject.load(s)
    res[s][:error].should == true
    res[s][:message].should include(s)
  end

  it "group update it settings" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    app = subject.application_by_name('app1')
    gr = subject.group_by_name('gr2')
    gr.config[:chain].should == {:restart => {:grace=>0.5, :action=>:restart}, :start => {:grace=>0.5, :action=>:start}}

    subject.load(fixture("dsl/load6.eye")).should_be_ok
    sleep 1

    gr.config[:chain].should == {:restart => {:grace=>1.0, :action=>:restart}, :start => {:grace=>1.0, :action=>:start}}
  end

  it "load multiple apps with cross constants" do
    subject.load(fixture('dsl/subfolder{2,3}.eye')).should_be_ok(2)
    subject.process_by_name('e1')[:working_dir].should == '/tmp'
    subject.process_by_name('e2')[:working_dir].should == '/var'

    subject.process_by_name('e3')[:working_dir].should == '/tmp'
    subject.process_by_name('e4')[:working_dir].should == '/'
  end

  it "raised load" do
    res = subject.load(fixture("dsl/load_error.eye")).only_value
    res[:error].should == true
    res[:message].should include("/asd/fasd/fas/df/asd/fas/df/d")
    set_glogger
  end

  describe "synchronize groups" do
    it "correctly schedule monitor for groups and processes" do
      subject.load(fixture("dsl/load_int.eye")).should_be_ok
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

      subject.load(fixture("dsl/load_int2.eye")).should_be_ok
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

  describe "load is exclusive" do
    it "run double in time" do
      subject.async.command(:load, fixture("dsl/long_load.eye"))
      subject.async.command(:load, fixture("dsl/long_load.eye"))
      sleep 2.5
      should_spend(0, 0.6) do
        subject.command(:info_data).should be_a(Hash)
      end
    end

    it "load with subloads" do
      silence_warnings{
        subject.command(:load, fixture("dsl/subfolder2.eye"))
      }
      sleep 0.5
      should_spend(0, 0.2) do
        subject.command(:info_data).should be_a(Hash)
      end
    end
  end

  describe "cleanup configs on delete" do
    it "load config, delete 1 process, load another config" do
      subject.load(fixture('dsl/load.eye'))
      subject.process_by_name('p1').should be

      subject.command(:delete, "p1"); sleep 0.1
      subject.process_by_name('p1').should be_nil

      subject.load(fixture('dsl/load2.eye'))
      subject.process_by_name('p1').should be_nil
    end

    it "load config, delete 1 group, load another config" do
      subject.load(fixture('dsl/load.eye'))
      subject.group_by_name('gr1').should be

      subject.command(:delete, "gr1"); sleep 0.1
      subject.group_by_name('p1').should be_nil

      subject.load(fixture('dsl/load2.eye'))
      subject.group_by_name('gr1').should be_nil
    end

    it "load config, then delete app, and load it with changed app-name" do
      subject.load(fixture('dsl/load3.eye'))
      subject.command(:delete, "app3"); sleep 0.1
      subject.load(fixture('dsl/load4.eye')).should_be_ok
    end

    it "delete from empty app (was an exception)" do
      subject.load_content(<<-F)
        Eye.app(:bla) { }
        Eye.app(:good) { group(:gr){}; process(:pr){ pid_file '1'} }
      F
      subject.command(:delete, "pr")
      subject.command(:delete, "gr")
      subject.command(:delete, "good")
      subject.command(:delete, "bla")
    end
  end

  it "should update only changed apps" do
    mock(subject).update_or_create_application('app1', is_a(Hash))
    mock(subject).update_or_create_application('app2', is_a(Hash))
    subject.load(fixture('dsl/load.eye'))

    mock(subject).update_or_create_application('app3', is_a(Hash))
    subject.load(fixture('dsl/load2.eye'))

    mock(subject).update_or_create_application('app3', is_a(Hash))
    subject.load(fixture('dsl/load3.eye'))
  end

  describe "load multiple" do
    it "ok load 2 configs" do
      subject.load(fixture("dsl/configs/1.eye"), fixture("dsl/configs/2.eye")).should_be_ok(2)
    end

    it "load 2 configs, 1 not exists" do
      res = subject.load(fixture("dsl/configs/1.eye"), fixture("dsl/configs/dddddd.eye"))
      res.size.should > 1
      res.errors_count.should == 1
    end

    it "multiple + folder" do
      res = subject.load(fixture("dsl/load.eye"), fixture("dsl/load_folder/"))
      res.ok_count.should == 3
      res.errors_count.should == 0
    end
  end

  describe "Load double processes with same names (was a bug)" do

    it "2 apps with procecesses with the same name" do
      cfg = <<-S
        Eye.app(:app) do
          group(:gr1) { process(:p) { pid_file "1.pid" } }
          group(:gr2) { process(:p) { pid_file "2.pid" } }
        end
      S

      subject.load_content(cfg)
      subject.load_content(cfg)

      Celluloid::Actor.all.select { |c| c.class == Eye::Process }.size.should == 2
    end

    it "2 process in different apps in __default__" do
      cfg = <<-S
        Eye.app(:app1) { process(:p) { pid_file "1.pid" } }
        Eye.app(:app2) { process(:p) { pid_file "2.pid" } }
      S

      subject.load_content(cfg)
      subject.load_content(cfg)

      Celluloid::Actor.all.select { |c| c.class == Eye::Process }.size.should == 2
    end

    it "2 process in different apps" do
      cfg = <<-S
        Eye.app(:app1) { group(:gr1) { process(:p) { pid_file "1.pid" } } }
        Eye.app(:app2) { group(:gr2) { process(:p) { pid_file "2.pid" } } }
      S

      subject.load_content(cfg)
      subject.load_content(cfg)

      Celluloid::Actor.all.select { |c| c.class == Eye::Process }.size.should == 2
      Celluloid::Actor.all.select { |c| c.class == Eye::Group }.size.should == 2
    end

    it "2 groups" do
      cfg = <<-S
        Eye.app(:app1) { group(:gr){} }
        Eye.app(:app2) { group(:gr){} }
      S

      subject.load_content(cfg)
      subject.load_content(cfg)

      Celluloid::Actor.all.select { |c| c.class == Eye::Group }.size.should == 2
    end
  end

  describe "valiadate localize params" do
    it "validate correct working_dir" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            working_dir "/tmp"
          end
        end
      E
      subject.load_content(conf).should_be_ok

      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            working_dir "/tmp/asdfsdf//sdf/asdf/asd/f/asdf"
          end
        end
      E
      subject.load_content(conf).errors_count.should == 1
      expect{ Eye::Dsl.parse_apps(conf) }.not_to raise_error(Eye::Process::Validate::Error)
    end

    [:uid, :gid].each do |s|
      it "validate user #{s}" do
        conf = <<-E
          Eye.application("bla") do
            process("1") do
              pid_file "1.pid"
              #{s} "root"
            end
          end
        E
        if RUBY_VERSION < '2.0' || (s == :gid && RUBY_PLATFORM.include?('darwin'))
          subject.load_content(conf).errors_count.should == 1
        else
          subject.load_content(conf).should_be_ok
        end

        conf = <<-E
          Eye.application("bla") do
            process("1") do
              pid_file "1.pid"
              #{s} "asdfasdff23rf234f323f"
            end
          end
        E
        subject.load_content(conf).errors_count.should == 1
      end
    end

  end
end
