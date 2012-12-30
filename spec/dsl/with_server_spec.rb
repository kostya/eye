require File.dirname(__FILE__) + '/../spec_helper'

describe "with_server feature" do

  it "should load matched by string process" do
    stub(Eye::SystemResources).host{ "server1" }

    conf = <<-E
      Eye.application("bla") do
        with_server "server1" do
          process("1"){ pid_file "1.pid" }
        end

        with_server "server2" do
          process("2"){ pid_file "2.pid" }
        end
      end
    E

    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "should another host conditions" do
    stub(Eye::SystemResources).host{ "server1" }

    conf = <<-E
      Eye.application("bla") do
        with_server %w{server1 server2} do
          process("1"){ pid_file "1.pid" }

          if Eye::SystemResources == 'server2'
            process("2"){ pid_file "2.pid" }
          end
        end
      end
    E

    Eye::Dsl.load(conf).should == {"bla"=>{:groups=>{"__default__"=>{:processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  describe "matches" do
    subject{ Eye::Dsl::Opts.new }

    it "match string" do
      stub(Eye::SystemResources).host{ "server1" }
      subject.with_server("server1").should == true
      subject.with_server("server2").should == false
      subject.with_server('').should == true
      subject.with_server(nil).should == true
    end

    it "match array" do
      stub(Eye::SystemResources).host{ "server1" }
      subject.with_server(%w{ server1 server2}).should == true
      subject.with_server(%w{ server2 server3}).should == false
    end

    it "match regexp" do
      stub(Eye::SystemResources).host{ "server1" }
      subject.with_server(%r{server}).should == true
      subject.with_server(%r{myserver}).should == false
    end
  end

end