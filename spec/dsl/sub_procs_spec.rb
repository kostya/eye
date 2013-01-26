require File.dirname(__FILE__) + '/../spec_helper'

describe "sub procs" do
  it "include lambda" do
    conf = <<-E
      proc = lambda do |proxy|
        proxy.working_dir "/tmp"
      end

      Eye.application("bla") do
        include proc        
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:working_dir=>"/tmp", :name => "bla"}}
  end

  it "include proc" do
    conf = <<-E
      proc = Proc.new do
        working_dir "/tmp"
      end

      Eye.application("bla") do
        include proc        
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:working_dir=>"/tmp", :name => "bla"}}
  end

  it "include method" do
    conf = <<-E
      def add_process(proxy)
        working_dir "/tmp"
      end

      Eye.application("bla") do
        include method(:add_process)
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:working_dir=>"/tmp", :name => "bla"}}
  end

  it "include method" do
    conf = <<-E
      def add_process(proxy)
        proxy.working_dir "/tmp"
      end

      Eye.application("bla") do
        include :add_process
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:working_dir=>"/tmp", :name => "bla"}}
  end

  it "include method" do
    conf = <<-E
      def add_process(proxy)
        working_dir "/tmp"
      end

      Eye.application("bla") do
        include :add_process
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:working_dir=>"/tmp", :name => "bla"}}
  end

  it "include method with params" do
    conf = <<-E
      def add_process(proxy, dir = 1)
        working_dir dir
      end

      Eye.application("bla") do
        include :add_process, "/tmp"
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:working_dir=>"/tmp", :name => "bla"}}
  end

end