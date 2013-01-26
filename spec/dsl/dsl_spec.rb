require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl" do

  it "fully empty config" do
    conf = <<-E
      # haha
    E
    Eye::Dsl.load(conf).should == {}
  end

  it "empty config" do
    conf = <<-E
      Eye.application("bla") do        
      end
    E
    Eye::Dsl.load(conf).should == {}
  end

  it "should set param " do
    conf = <<-E
      Eye.application("bla") do        
        start_timeout 10.seconds
      end
    E
    Eye::Dsl.load(conf).should == {"bla"=>{:start_timeout => 10.seconds, :groups => {}}}
  end

  it "should set param, with self and =" do
    conf = <<-E
      Eye.application("bla") do        
        self.start_timeout = 10.seconds
      end
    E
    Eye::Dsl.load(conf).should == {"bla"=>{:start_timeout => 10.seconds, :groups => {}}}
  end

  it "another block syntax" do
    conf = <<-E
      Eye.application("bla"){ start_timeout 10.seconds }
    E
    Eye::Dsl.load(conf).should == {"bla"=>{:start_timeout => 10.seconds, :groups => {}}}
  end

  it "should raise on unknown option" do
    conf = <<-E
      Eye.application("bla") do        
        pid_file "11"
        hoho 10
      end
    E
    expect{Eye::Dsl.load(conf)}.to raise_error(Eye::Dsl::Error)
  end

  it "hash should not be with defaults" do
    conf = <<-E
      Eye.application("bla") do
        start_timeout 10.seconds

        process("11") do
          pid_file "1"
        end
      end
    E
    cfg = Eye::Dsl.load(conf)
    cfg[:something].should == nil
    cfg['bla'][:something].should == nil
    cfg['bla'][:groups]['__default__'][:some].should == nil
    cfg['bla'][:groups]['__default__'][:processes][:some].should == nil
  end

  describe "global options" do
    it "logger" do
      conf = <<-E
        Eye.logger = "/tmp/1.log"
        Eye.logger_level = Logger::DEBUG

        Eye.application("bla") do        
        end
      E
      Eye::Dsl.load(conf).should == {}
      Eye.parsed_options.should == {:logger => "/tmp/1.log", :logger_level => Logger::DEBUG}
    end
  end

end