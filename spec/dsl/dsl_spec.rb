require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl" do

  it "fully empty config" do
    conf = <<-E
      # haha
    E
    Eye::Dsl.parse(conf).to_h.should == {:applications => {}, :settings => {}}
    Eye::Dsl.parse_apps(conf).should == {}
  end

  it "empty config" do
    conf = <<-E
      Eye.application("bla") do
      end
    E
    Eye::Dsl.parse_apps(conf).should == {'bla' => {:name => "bla"}}
  end

  it "should set param " do
    conf = <<-E
      Eye.application("bla") do
        start_timeout 10.seconds
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:start_timeout => 10.seconds, :name => "bla"}}
  end

  it "should set param, with self and =" do
    conf = <<-E
      Eye.application("bla") do
        self.start_timeout = 10.seconds
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:start_timeout => 10.seconds, :name => "bla"}}
  end

  it "another block syntax" do
    conf = <<-E
      Eye.application("bla"){ start_timeout 10.seconds }
    E
    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:start_timeout => 10.seconds, :name => "bla"}}
  end

  it "should raise on unknown option" do
    conf = <<-E
      Eye.application("bla") do
        pid_file "11"
        hoho 10
      end
    E
    expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
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
    cfg = Eye::Dsl.parse_apps(conf)
    cfg[:something].should == nil
    cfg['bla'][:something].should == nil
    cfg['bla'][:groups]['__default__'][:some].should == nil
    cfg['bla'][:groups]['__default__'][:processes][:some].should == nil
  end

  it "should set application defaults" do
    conf = <<-E
      Eye.application('__default__'){ env "A" => "B" }
      Eye.application(:__default__){ env "B" => "C" }

      Eye.application("bla") do
        process("11") do
          pid_file "1"
        end
      end
    E
    cfg = Eye::Dsl.parse_apps(conf)
    cfg['bla'][:environment].should == {"A"=>"B", "B"=>"C"}
    cfg['bla'][:groups]['__default__'][:processes]['11'][:environment].should == {"A"=>"B", "B"=>"C"}
  end

  it "set uid option" do
    conf = <<-E
      Eye.application("bla") do
        uid "vasya"

        process("11") do
          pid_file "1"
        end
      end
    E

    if RUBY_VERSION >= '2.0'
      expect{Eye::Dsl.parse_apps(conf)}.not_to raise_error(Eye::Dsl::Error)
    else
      expect{Eye::Dsl.parse_apps(conf)}.to raise_error(Eye::Dsl::Error)
    end
  end

  it "should set clear_bundler_env" do
    conf = " Eye.app(:bla){  clear_bundler_env; env 'A' => 1 }"
    cfg = Eye::Dsl.parse_apps(conf)
    cfg['bla'][:environment].should == {"GEM_PATH"=>nil, "GEM_HOME"=>nil, "RUBYOPT"=>nil, "BUNDLE_BIN_PATH"=>nil, "BUNDLE_GEMFILE"=>nil, "A" => 1}
  end


end
