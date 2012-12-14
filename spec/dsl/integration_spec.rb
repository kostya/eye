require File.dirname(__FILE__) + '/../spec_helper'

# check that result hash is pure, without autocreated keys
def check_pure_hash(gk, h)
  h.each do |k, v|
    if v.is_a?(Hash) && v.present?
      check_pure_hash(k, v)
    end

    begin
      raise "not pure hash" if h[:not_exists_key] != nil
    rescue
      raise "problem with key #{gk}"
    end
  end
end

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
              stop_command "kill -9 {{PID}}"
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
      {
        :environment=>{"ENV1"=>"1"}, 
        :working_dir=>"/tmp", 
        :groups=>{
          "mini"=>{
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
                :daemonize=>true, 
                :monitor_children=>{
                  :stop_command=>"kill -9 {{PID}}", 
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
          "__default__"=>{
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

    res = Eye::Dsl.load(conf)
    res.should == h
    check_pure_hash(:root, res)
  end

  it "should merge environment" do
    conf = <<-E
      Eye.application("bla") do
        environment "HAH" => "1"

        group("moni") do
          environment "HAHA" => "2"

          process("1") do
            pid_file "1"
          end
        end

        process("2") {pid_file "2"}
      end
    E

    h = {'bla' => 
      {
        :environment=>{"HAH"=>"1"}, 
        :groups=>{
          "moni"=>{
            :environment=>{"HAHA"=>"2", "HAH"=>"1"}, 
            :processes=>{
              "1"=>{
                :environment=>{"HAHA"=>"2", "HAH"=>"1"}, 
                :pid_file=>"1", 
                :application=>"bla", 
                :group=>"moni", 
                :name=>"1"}}},
          "__default__"=>{
            :environment=>{"HAH"=>"1"}, 
            :processes=>{
              "2"=>{
                :environment=>{"HAH"=>"1"}, 
                :pid_file=>"2", 
                :application=>"bla", 
                :group=>"__default__", 
                :name=>"2"}}}}}
    }

    Eye::Dsl.load(conf).should == h
    check_pure_hash(:root, Eye::Dsl.load(conf))
  end

  it "should rewrite options" do
    conf = <<-E
      Eye.application("bla") do
        working_dir "/tmp"

        group("moni") do
          working_dir "/nah"

          process("1") do
            pid_file "1"
            working_dir "/1"
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
      {
        :working_dir=>"/tmp", 
        :groups=>{
          "moni"=>{
            :working_dir=>"/nah", 
            :processes=>{
              "1"=>{
                :working_dir=>"/1", 
                :pid_file=>"1", 
                :application=>"bla", 
                :group=>"moni", 
                :name=>"1"}, 
              "2"=>{
                :working_dir=>"/nah", 
                :pid_file=>"2", 
                :application=>"bla", 
                :group=>"moni", 
                :name=>"2"}}}, 
          "__default__"=>{
            :working_dir=>"/tmp", 
            :processes=>{
              "3"=>{
                :working_dir=>"/tmp", 
                :pid_file=>"3", 
                :application=>"bla", 
                :group=>"__default__", 
                :name=>"3"}}}}}
    }

    Eye::Dsl.load(conf).should == h
    check_pure_hash(:root, Eye::Dsl.load(conf))
  end

  describe "requires" do
    before :each do
      @h = {'bla' => 
      {
        :working_dir=>"/tmp", 
        :groups=>{
          "__default__"=>{
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
      Eye::Dsl.load(conf, file).should == @h
      check_pure_hash(:root, Eye::Dsl.load(conf, file))
    end

    it "should require other files by require" do
      file = fixture('dsl/0a.rb')
      conf = File.read(file)
      Eye::Dsl.load(conf, file).should == @h
    end    

    it "should load by load" do
      file = fixture('dsl/0c.rb')
      conf = File.read(file)
      Eye::Dsl.load(conf, file).should == @h
    end
  end

end