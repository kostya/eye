require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl checks" do

  it "ok checks" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          pid_file "1.pid"

          checks :memory, :below => 100.megabytes, :every => 10.seconds
          checks :cpu,    :below => 100, :every => 20.seconds
        end        
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}, :cpu=>{:below=>100, :every=>20, :type=>:cpu}}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "inherit checks" do
    conf = <<-E
      Eye.application("bla") do
        checks :memory, :below => 100.megabytes, :every => 10.seconds

        process("1") do
          pid_file "1.pid"

          checks :memory, :below => 90.megabytes, :every => 5.seconds  
          checks :cpu,    :below => 100, :every => 20.seconds
        end        

        process("2") do
          pid_file "2.pid"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :processes=>{"1"=>{:checks=>{:memory=>{:below=>94371840, :every=>5, :type=>:memory}, :cpu=>{:below=>100, :every=>20, :type=>:cpu}}, :pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}, "2"=>{:checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"2"}}}}}}
  end

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

  it "no valid checks" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          pid_file "1.pid"
          checks :cpu,    :below => {1 => 2}, :every => 20.seconds
        end        
      end
    E
    expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Validation::Error)
  end

  it "ok trigger" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          pid_file "1.pid"

          triggers :flapping, :times => 2, :within => 15.seconds
        end        
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :triggers=>{:flapping=>{:times=>2, :within=>15, :type=>:flapping}}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "no valid trigger" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          pid_file "1.pid"
          triggers :flapping, :times => 2, :within => "bla"
        end        
      end
    E
    expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Validation::Error)
  end

  it "nochecks to remove inherit checks" do
    conf = <<-E
      Eye.application("bla") do
        checks :memory, :below => 100.megabytes, :every => 10.seconds

        process("1") do
          pid_file "1.pid"
          nochecks :memory
        end        

        process("2") do
          pid_file "2.pid"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, 
      :groups=>{
        "__default__"=>{:name => "__default__", :application => "bla", 
          :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, 
          :processes=>{
            "1"=>{:checks=>{}, :pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}, 
            "2"=>{:checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"2"}}}}}}
  end

  it "empty nocheck do nothing and inherit" do
    conf = <<-E
      Eye.application("bla") do
        checks :memory, :below => 100.megabytes, :every => 10.seconds
        nochecks :cpu

        group :blagr do
          process("1") do
            pid_file "1.pid"
            nochecks :cpu
            nochecks :memory
          end        
        end

        process("2") do
          pid_file "2.pid"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", 
        :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, 
        :groups=>{
          "blagr" => {:name=>"blagr", :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :application=>"bla",
            :processes => {"1"=>{:checks=>{}, :pid_file=>"1.pid", :application=>"bla", :group=>"blagr", :name=>"1"}}},
          "__default__"=>{:name => 
            "__default__", :application => "bla", 
            :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :processes=>{ 
              "2"=>{:checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"2"}}}}}}
  end

  it "process with unknown checker type" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.process("1") do
          pid_file "2.pid"

          checks :bla, :a => 1
        end        
      end
    E
    expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
  end

  it "process with unknown triggers type" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.process("1") do
          pid_file "2.pid"

          triggers :bla, :a => 1
        end        
      end
    E
    expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
  end

  it "check with Proc" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          pid_file "1.pid"

          checks :socket, :addr => "unix:/tmp/1", :expect_data => Proc.new{|data| data == 1}
        end        

        process("3") do
          pid_file "3.pid"

          checks :socket, :addr => "unix:/tmp/3", :expect_data => /regexp/
        end        

        process("2") do
          pid_file "2.pid"

          checks :socket, :addr => "unix:/tmp/2", :expect_data => Proc.new{|data| data == 1}
        end        

      end
    E
    res = Eye::Dsl.parse_apps(conf)
    proc = res['bla'][:groups]['__default__'][:processes]['1'][:checks][:socket][:expect_data]
    proc[0].should == false
    proc[1].should == true

    proc = res['bla'][:groups]['__default__'][:processes]['2'][:checks][:socket][:expect_data]
    proc[0].should == false
    proc[1].should == true
  end

end
