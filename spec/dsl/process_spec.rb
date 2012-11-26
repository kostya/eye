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
    expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)    
  end

  it "valid process" do
    conf = <<-E
      Eye.application("bla") do
        process("1") do
          pid_file "1.pid"
        end        
      end
    E
    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"0"=>{:pid_file=>"0.pid", :application=>"bla", :group=>"__default__", :name=>"0"}, "1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}, "2"=>{:pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"2"}}}}}}
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
    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
    expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)    
  end

  it "when 2 processes with same name, should squash" do
    conf = <<-E
      Eye.application("bla") do
        process("1"){pid_file "11"}
        process("1"){pid_file "12"}
      end
    E
    Eye::Dsl.load(conf).should == {'bla' => {:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"12", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
      Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:stdout=>"1.log", :stderr=>"2.log", :pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
      Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:stdout=>"1.log", :stderr=>"1.log", :pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
      expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)    
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
      expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)    
    end
  end

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
      Eye::Dsl.load(conf).should == {"bla" => {:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :monitor_children=>{:restart_command=>"kill"}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
      expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)    
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
      expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)    
    end

  end

  describe "checks, triggers" do
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
      Eye::Dsl.load(conf).should == {"bla" => {:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}, :cpu=>{:below=>100, :every=>20, :type=>:cpu}}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
      Eye::Dsl.load(conf).should == {"bla" => {:checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :groups=>{"__default__"=>{:checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :processes=>{"1"=>{:checks=>{:memory=>{:below=>94371840, :every=>5, :type=>:memory}, :cpu=>{:below=>100, :every=>20, :type=>:cpu}}, :pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}, "2"=>{:checks=>{:memory=>{:below=>104857600, :every=>10, :type=>:memory}}, :pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"2"}}}}}}
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
      Eye::Dsl.load(conf).should == {"bla" => {:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :monitor_children=>{:checks=>{:cpu=>{:below=>100, :every=>20, :type=>:cpu}}}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
    end

    xit "child should inherit checks" do
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
      Eye::Dsl.load(conf).should == {"bla" => {:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :monitor_children=>{:checks=>{:cpu=>{:below=>100, :every=>20, :type=>:cpu}}}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
      Eye::Dsl.load(conf).should == {"bla" => {:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :triggers=>{:flapping=>{:times=>2, :within=>15, :type=>:flapping}}, :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "valid process with proxies" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.process("1") do |p|
          p.pid_file = "2.pid"
        end        
      end
    E
    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"2.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
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
    expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)
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
    expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)
  end


end