require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl" do

  it "process without pid_file should raise" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          stdout "1.log"
        end
      end
    E
    expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
  end

  it "valid process" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          pid_file "1.pid"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "process return Object" do
    conf = <<-E
    Eye.application("bla") do
      p = process("1") { pid_file "1.pid" }
      env "A" => p.pid_file
    end
    E
    Eye::Dsl.parse_apps(conf)['bla'][:environment].should == {'A' => '1.pid'}
  end

  it "disable process" do
    conf = <<-E
      Eye.application("bla") do
        env "a" => 'b'
        xprocess("1") do
          pid_file "1.pid"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:environment=>{"a"=>"b"}, :name => "bla"}}
  end

  it "process with times" do
    conf = <<-E
      Eye.application("bla") do
        2.times do |i|
          process("\#{i}") do
            pid_file "\#{i}.pid"
          end
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"0"=>{:pid_file=>"0.pid", :application=>"bla", :group=>"__default__", :name=>"0"}, "1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "process with def" do
    conf = <<-E
      def add_process(proxy, name)
        proxy.process(name) do
          pid_file "\#{name}.pid"
        end
      end

      Eye.application("bla") do
        add_process(self, "1")
        add_process(self, "2")
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}, "2"=>{:pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"2"}}}}}}
  end

  it "process with constant" do
    conf = <<-E
      BLA = "1.pid"

      Eye.application("bla") do
        process("1") do
          pid_file BLA
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "when 2 processes with same pid_file, its ERROR" do
    conf = <<-E
      def add_process(proxy, name)
        proxy.process(name) do
          pid_file "same.pid"
        end
      end

      Eye.application("bla") do
        add_process(self, "1")
        add_process(self, "2")
      end
    E
    expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
  end

  it "when 2 processes with same name, should squash" do
    conf = <<-E
      Eye.application("bla") do
        process("1"){pid_file "11"}
        process("1"){pid_file "12"}
      end
    E
    Eye::Dsl.parse_apps(conf).should == {'bla' => {:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"12", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  describe "stdout, stder, stdall" do
    it "stdout, stderr" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            stdout  "1.log"
            stderr "2.log"
            pid_file "1.pid"
          end
        end
      E
      Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:stdout=>"1.log", :stderr=>"2.log", :pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
    end

    it "stdall" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            stdall   "1.log"
            pid_file "1.pid"
          end
        end
      E
      Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:stdout=>"1.log", :stderr=>"1.log", :stdall => "1.log", :pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
    end

  end

  describe "pid_file is invalid" do
    it "pid_file in app is invalid" do
      conf = <<-E
        Eye.application("bla") do
          pid_file "11"

          process("1") do
            pid_file "12"
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

    it "pid_file in group is invalid" do
      conf = <<-E
        Eye.application("bla") do

          group("mini") do
            pid_file "11"
            process("1"){ pid_file "12" }
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end
  end


  it "valid process with proxies" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.process("1") do |p|
          p.pid_file "2.pid"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "valid process with proxies" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.process("1") do |p|
          p.pid_file = "2.pid"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  describe "blank envs" do

    it "empty env" do
      conf = <<-E
        Eye.application("bla") do
          env nil
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

    it "empty env" do
      conf = <<-E
        Eye.application("bla") do
          env []
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

    it "empty env" do
      conf = <<-E
        Eye.application("bla") do
          env 'asdfsdf'
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

    it "should accept nil value" do
      conf = <<-E
        Eye.application("bla") do
          env "SOME" => nil
        end
      E
      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :environment=>{"SOME"=>nil}}}
    end

  end

  describe "validation" do
    it "bad string" do
      conf = "Eye.app('bla'){ self.working_dir = {} }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.working_dir = [] }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.working_dir = 5.6 }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.working_dir = false }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

    it "good string" do
      conf = "Eye.app('bla'){ self.working_dir = nil }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.working_dir = 'bla' }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)
    end

    it "bad bool" do
      conf = "Eye.app('bla'){ self.clear_pid = {} }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.clear_pid = [] }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.clear_pid = 5.6 }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.clear_pid = 'false' }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

    it "good bool" do
      conf = "Eye.app('bla'){ self.clear_pid = nil }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.clear_pid = true }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.clear_pid = false }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)
    end

    it "bad interval" do
      conf = "Eye.app('bla'){ self.clear_pid = {} }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.start_timeout = [] }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.start_timeout = false }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.start_timeout = 'false' }"
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

    it "good interval" do
      conf = "Eye.app('bla'){ self.start_timeout = nil }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.start_timeout = 10.seconds }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)

      conf = "Eye.app('bla'){ self.start_timeout = 1.5.seconds }"
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)
    end

  end

  describe "process validations" do
    it "validate daemonize command" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            daemonize true
            start_command "sh -c 'echo some; ruby 1.rb'"
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Process::Validate::Error)

      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            daemonize true
            start_command "echo some && ruby 1.rb"
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Process::Validate::Error)

      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            daemonize true
            start_command "ruby 1.rb"
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Process::Validate::Error)
    end

    it "not validate non-daemonize command" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            start_command "sh -c 'echo some && ruby 1.rb'"
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Process::Validate::Error)
    end

    it "validate correct working_dir" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            working_dir "/tmp"
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Process::Validate::Error)

      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            working_dir "/tmp/asdfsdf//sdf/asdf/asd/f/asdf"
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Process::Validate::Error)
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
        if RUBY_VERSION >= '2.0'
          expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error
        else
          expect{Eye::Dsl.parse_apps(conf)}.to raise_error
        end

        conf = <<-E
          Eye.application("bla") do
            process("1") do
              pid_file "1.pid"
              #{s} "asdfasdff23rf234f323f"
            end
          end
        E
        expect{Eye::Dsl.parse_apps(conf)}.to raise_error
      end
    end

  end

end
