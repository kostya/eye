require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl" do
  describe "child process" do
    it "ok child monitor" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            monitor_children{ restart_command "kill" }
          end
        end
      E
      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :monitor_children=>{:restart_command=>"kill"}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
    end

    it "child invalid command" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            monitor_children{ restart_some "kill" }
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(NoMethodError)
    end

    it "child pid_file" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            monitor_children{ pid_file "2.pid" }
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end

  end

  describe "checks" do
    it "checks in monitor_children" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            monitor_children{
              checks :cpu,    :below => 100, :every => 20.seconds
            }
          end
        end
      E
      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :monitor_children=>{:checks=>{:cpu=>{:below=>100, :every=>20, :type=>:cpu}}}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
    end

    it "child should not inherit checks" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            checks :cpu,    :below => 100, :every => 20.seconds
            monitor_children{
            }
          end
        end
      E
      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :groups=>{"__default__"=>{:name=>"__default__", :application=>"bla", :processes=>{"1"=>{:name=>"1", :application=>"bla", :group=>"__default__", :pid_file=>"1.pid", :checks=>{:cpu=>{:below=>100, :every=>20, :type=>:cpu}}, :monitor_children=>{}}}}}}}
    end

    it "trigger should raise" do
      conf = <<-E
        Eye.application("bla") do
          process("1") do
            pid_file "1.pid"
            monitor_children{ trigger :stop_children }
          end
        end
      E
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end
  end
end
