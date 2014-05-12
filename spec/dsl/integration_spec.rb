require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl" do
  it "intergration spec" do
    conf = <<-E
      Eye.application("bla") do
        environment "ENV1" => "1"
        working_dir "/tmp"

        group("mini") do
          process("1") do
            start_command "echo start"
            stop_command "echo end"
            pid_file  "1.pid"
            stdall    "1.log"
            daemonize   true

            monitor_children do
              stop_command "kill -9 {PID}"
              checks :memory, :every => 30.seconds, :below => 200.megabytes
              checks :cpu, :every => 30.seconds, :below => 10, :times => [3,5]
            end

            checks :memory, :every => 20.seconds, :below => 100.megabytes, :times => [3,5]
            triggers :flapping, :times => 3, :within => 30.seconds
          end
        end

        process("2") do
          pid_file "h"
        end
      end
    E

    h = {'bla' =>
      { :name => "bla",
        :environment=>{"ENV1"=>"1"},
        :working_dir=>"/tmp",
        :groups=>{
          "mini"=>{:name => "mini", :application => "bla",
            :environment=>{"ENV1"=>"1"},
            :working_dir=>"/tmp",
            :processes=>{
              "1"=>{
                :environment=>{"ENV1"=>"1"},
                :working_dir=>"/tmp",
                :start_command=>"echo start",
                :stop_command=>"echo end",
                :pid_file=>"1.pid",
                :stderr=>"1.log",
                :stdout=>"1.log",
                :stdall=>"1.log",
                :daemonize=>true,
                :monitor_children=>{
                  :stop_command=>"kill -9 {PID}",
                  :checks=>{:memory=>{:every=>30, :below=>209715200, :type=>:memory},
                  :cpu=>{:every=>30, :below=>10, :times=>[3, 5], :type=>:cpu}}
                  },
                :checks=>{
                  :memory=>{:every=>20, :below=>104857600, :times=>[3, 5], :type=>:memory}
                },
                :triggers=>{
                  :flapping=>{:times=>3, :within=>30, :type=>:flapping}
                },
                :application=>"bla",
                :group=>"mini",
                :name=>"1"}}},
          "__default__"=>{:name => "__default__", :application => "bla",
            :environment=>{"ENV1"=>"1"},
            :working_dir=>"/tmp",
            :processes=>{
              "2"=>{
                :environment=>{"ENV1"=>"1"},
                :working_dir=>"/tmp",
                :pid_file=>"h",
                :application=>"bla",
                :group=>"__default__",
                :name=>"2"}}}}}
    }

    res = Eye::Dsl.parse_apps(conf)
    res.should == h
  end

  it "merging envs inside one process" do
    conf = <<-E
      Eye.application "bla" do
        environment "RAILS_ENV" => "test"
        environment "LANG" => "ru_RU.UTF-8"

        process("1") do
          environment "A" => "1"
          env "B" => "2"

          pid_file "1"
        end
      end
    E
    res = Eye::Dsl.parse_apps(conf)
    res["bla"][:environment].should ==
      {"RAILS_ENV" => "test", "LANG" => "ru_RU.UTF-8"}

    res["bla"][:groups]["__default__"][:environment].should ==
      {"RAILS_ENV" => "test", "LANG" => "ru_RU.UTF-8"}

    res["bla"][:groups]["__default__"][:processes]['1'][:environment].should ==
      {"RAILS_ENV" => "test", "LANG" => "ru_RU.UTF-8", "A" => "1", "B" => "2"}
  end

  it "should merge environment" do
    conf = <<-E
      Eye.application("bla") do
        environment "HAH" => "1"

        group("moni") do
          environment "HAHA" => "2"

          process("1") do
            environment "HEHE" => "4"
            pid_file "1"
          end
        end

        process("2") do
          environment "HOHO" => "3"
          pid_file "2"
        end
      end
    E

    h = {'bla' =>
      { :name => "bla",
        :environment=>{"HAH"=>"1"},
        :groups=>{
          "moni"=>{:name => "moni", :application => "bla",
            :environment=>{"HAHA"=>"2", "HAH"=>"1"},
            :processes=>{
              "1"=>{
                :environment=>{"HAHA"=>"2", "HAH"=>"1", "HEHE" => "4"},
                :pid_file=>"1",
                :application=>"bla",
                :group=>"moni",
                :name=>"1"}}},
          "__default__"=>{:name => "__default__", :application => "bla",
            :environment=>{"HAH"=>"1"},
            :processes=>{
              "2"=>{
                :environment=>{"HAH"=>"1", "HOHO" => "3"},
                :pid_file=>"2",
                :application=>"bla",
                :group=>"__default__",
                :name=>"2"}}}}}
    }

    Eye::Dsl.parse_apps(conf).should == h
  end

  it "should rewrite options" do
    conf = <<-E
      Eye.application("bla") do
        umask 111

        group("moni") do
          umask 222

          process("1") do
            pid_file "1"
            umask 333
          end

          process("2") do
            pid_file "2"
          end
        end

        process("3") do
          pid_file "3"
        end
      end
    E

    h = {'bla' =>
      { :name => "bla",
        :umask=>111,
        :groups=>{
          "moni"=>{:name => "moni", :application => "bla",
            :umask=>222,
            :processes=>{
              "1"=>{
                :umask=>333,
                :pid_file=>"1",
                :application=>"bla",
                :group=>"moni",
                :name=>"1"},
              "2"=>{
                :umask=>222,
                :pid_file=>"2",
                :application=>"bla",
                :group=>"moni",
                :name=>"2"}}},
          "__default__"=>{:name => "__default__", :application => "bla",
            :umask=>111,
            :processes=>{
              "3"=>{
                :umask=>111,
                :pid_file=>"3",
                :application=>"bla",
                :group=>"__default__",
                :name=>"3"}}}}}
    }
    Eye::Dsl.parse_apps(conf).should == h
  end

  describe "requires" do
    before :each do
      @h = {'bla' =>
      { :name => "bla",
        :working_dir=>"/tmp",
        :groups=>{
          "__default__"=>{
            :name => "__default__", :application => "bla",
            :working_dir=>"/tmp",
            :processes=>{
              "11"=>{
                :working_dir=>"/tmp",
                :pid_file=>"11.pid",
                :application=>"bla",
                :group=>"__default__",
                :name=>"11"},
              "12"=>{
                :working_dir=>"/tmp",
                :pid_file=>"12.pid",
                :application=>"bla",
                :group=>"__default__",
                :name=>"12"}}}}}

      }
    end

    it "should require other files by require" do
      file = fixture('dsl/0.rb')
      conf = File.read(file)
      Eye::Dsl.parse_apps(conf, file).should == @h
    end

    it "should require other files by require" do
      file = fixture('dsl/0a.rb')
      conf = File.read(file)
      Eye::Dsl.parse_apps(conf, file).should == @h
    end

    it "should load by load" do
      file = fixture('dsl/0c.rb')
      conf = File.read(file)
      Eye::Dsl.parse_apps(conf, file).should == @h
    end
  end

  it "recursive merge cases" do
    conf = <<-E
      Eye.application("bla") do
        working_dir "/tmp"
        env 'A' => '1'
        group :bla do
          env 'C' => '1'
          process("1"){ pid_file '1'}

          env 'D' => '1'
          process("2"){ pid_file '2'}
        end

        working_dir "/tmp2"
        env 'B' => '1'
        group :bla2 do
          # /tmp2
        end
      end
    E

    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", :working_dir=>"/tmp2", :environment=>{"A"=>"1", "B"=>"1"}, :groups=>{
        "bla"=>{:name => "bla", :application => "bla", :working_dir=>"/tmp", :environment=>{"A"=>"1", "C"=>"1", "D"=>"1"},
        :processes=>{
          "1"=>{:working_dir=>"/tmp", :environment=>{"A"=>"1", "C"=>"1"}, :group=>"bla", :application=>"bla", :name=>"1", :pid_file=>"1"},
          "2"=>{:working_dir=>"/tmp", :environment=>{"A"=>"1", "C"=>"1", "D"=>"1"}, :group=>"bla", :application=>"bla", :name=>"2", :pid_file=>"2"}}},
        "bla2"=>{:name => "bla2", :application => "bla", :working_dir=>"/tmp2", :environment=>{"A"=>"1", "B"=>"1"}}}}}
  end

  it "join group spec" do
    conf = <<-E
      Eye.application("bla") do
        group :blagr do
          process("1"){ pid_file '1'}
        end

        group :blagr do
          env 'P' => '1'
          process("2"){ pid_file '2'}
        end
      end
    E

    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", :groups=>{
        "blagr"=>{:name => "blagr", :application => "bla", :processes=>{
          "1"=>{:group=>"blagr", :application=>"bla", :name=>"1", :pid_file=>"1"},
          "2"=>{:environment=>{"P"=>"1"}, :group=>"blagr", :application=>"bla", :name=>"2", :pid_file=>"2"}},
        :environment=>{"P"=>"1"}}}}}
  end


  describe "scoped" do
    it "scoped" do
      conf = <<-E
        Eye.application("bla") do
          group :gr do
            env "A" => '1', "B" => '2'

            process :a do
              pid_file "1.pid"
            end

            scoped do
              env "A" => '2'

              process :b do
                pid_file "2.pid"
              end
            end

            process :c do
              pid_file "3.pid"
            end
          end
        end
      E

      Eye::Dsl.parse_apps(conf).should == {
        "bla" => {:name=>"bla", :groups=>{
          "gr"=>{:name=>"gr", :application=>"bla", :environment=>{"A"=>"1", "B"=>"2"},
            :processes=>{
              "a"=>{:name=>"a", :application=>"bla", :environment=>{"A"=>"1", "B"=>"2"}, :group=>"gr", :pid_file=>"1.pid"},
              "b"=>{:name=>"b", :application=>"bla", :environment=>{"A"=>"2", "B"=>"2"}, :group=>"gr", :pid_file=>"2.pid"},
              "c"=>{:name=>"c", :application=>"bla", :environment=>{"A"=>"1", "B"=>"2"}, :group=>"gr", :pid_file=>"3.pid"}}}}}}
    end

    it "scoped" do
      conf = <<-E
        Eye.application("bla") do
          start_timeout 10.seconds

          group(:a){}

          scoped do
            start_timeout 15.seconds
            group(:b){
              scoped do

              end
            }
          end

          group(:c){}
        end
      E

      Eye::Dsl.parse_apps(conf).should == {
        "bla" => {:name=>"bla", :start_timeout=>10, :groups=>{
          "a"=>{:name=>"a", :start_timeout=>10, :application=>"bla"},
          "b"=>{:name=>"b", :start_timeout=>15, :application=>"bla"},
          "c"=>{:name=>"c", :start_timeout=>10, :application=>"bla"}}}}
    end

  end

end
