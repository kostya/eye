require File.dirname(__FILE__) + '/../spec_helper'

describe "with_server feature" do

  it "should load matched by string process" do
    stub(Eye::Local).host{ "server1" }

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

    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "should another host conditions" do
    stub(Eye::Local).host{ "server1" }

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

    Eye::Dsl.parse_apps(conf).should == {"bla"=>{:name => "bla", :groups=>{"__default__"=>{:name => "__default__", :application => "bla", :processes=>{"1"=>{:pid_file=>"1.pid", :application=>"bla", :group=>"__default__", :name=>"1"}}}}}}
  end

  it "should behaves like scoped" do
    stub(Eye::Local).host{ "server1" }

    conf = <<-E
      Eye.application("bla") do
        env "A" => "B"
        with_server /server1/ do
          env "A" => "C"
          group(:a){}
        end

        group(:b){}
      end
    E

    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name=>"bla", :environment=>{"A"=>"B"},
        :groups=>{
          "a"=>{:name=>"a", :environment=>{"A"=>"C"}, :application=>"bla"},
          "b"=>{:name=>"b", :environment=>{"A"=>"B"}, :application=>"bla"}}}}
  end

  describe "matches" do
    subject{ Eye::Dsl::Opts.new }

    it "match string" do
      stub(Eye::Local).host{ "server1" }
      subject.with_server("server1").should == true
      subject.with_server("server2").should == false
      subject.with_server('').should == true
      subject.with_server(nil).should == true
    end

    it "match array" do
      stub(Eye::Local).host{ "server1" }
      subject.with_server(%w{ server1 server2}).should == true
      subject.with_server(%w{ server2 server3}).should == false
    end

    it "match regexp" do
      stub(Eye::Local).host{ "server1" }
      subject.with_server(%r{server}).should == true
      subject.with_server(%r{myserver}).should == false
    end
  end

  describe "helpers" do
    it "hostname on with server" do
      conf = <<-E
        x = current_config_path
        Eye.application("bla"){
          with_server('muga_server') do
            working_dir "/tmp"
          end
        }
      E
      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla"}}
    end

    it "with_server work" do
      Eye::Local.host = 'mega_server'

      conf = <<-E
        Eye.application("bla"){
          with_server('mega_server') do
            group :blo do
              working_dir "/tmp"
            end
          end
        }
      E
      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :groups=>{"blo"=>{:name=>"blo", :application=>"bla", :working_dir=>"/tmp"}}}}
    end

    it "hostname work" do
      Eye::Local.host = 'supa_server'

      conf = <<-E
        Eye.application("bla"){
          working_dir "/tmp"
          env "HOST" => hostname
        }
      E
      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :working_dir=>"/tmp", :environment=>{"HOST"=>"supa_server"}}}
    end

  end

  describe "Merging groups in scoped" do
    it "double with_server (was a bug)" do
      stub(Eye::Local).host{ "server1" }

      conf = <<-E
        Eye.application("bla") do
          with_server "server1" do
            process("1"){ pid_file "1.pid" }
          end

          with_server "server1" do
            process("2"){ pid_file "2.pid" }
          end
        end
      E

      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :groups=>{"__default__"=>{:name=>"__default__", :application=>"bla", :processes=>{"1"=>{:name=>"1", :application=>"bla", :group=>"__default__", :pid_file=>"1.pid"}, "2"=>{:name=>"2", :application=>"bla", :group=>"__default__", :pid_file=>"2.pid"}}}}}}
    end

    it "double with_server in a group" do
      stub(Eye::Local).host{ "server1" }

      conf = <<-E
        Eye.application("bla") do
          group :bla do
            with_server "server1" do
              process("1"){ pid_file "1.pid" }
            end

            with_server "server1" do
              process("2"){ pid_file "2.pid" }
            end
          end
        end
      E

      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :groups=>{"bla"=>{:name=>"bla", :application=>"bla", :processes=>{"1"=>{:name=>"1", :application=>"bla", :group=>"bla", :pid_file=>"1.pid"}, "2"=>{:name=>"2", :application=>"bla", :group=>"bla", :pid_file=>"2.pid"}}}}}}
    end

    it "double with_server in a group" do
      stub(Eye::Local).host{ "server1" }

      conf = <<-E
        Eye.application("bla") do
          with_server "server1" do
            group :gr1 do
              process("1"){ pid_file "1.pid" }
            end
          end

          with_server "server1" do
            group :gr1 do
              process("2"){ pid_file "2.pid" }
            end
          end
        end
      E

      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :groups=>{"gr1"=>{:name=>"gr1", :application=>"bla", :processes=>{"1"=>{:name=>"1", :application=>"bla", :group=>"gr1", :pid_file=>"1.pid"}, "2"=>{:name=>"2", :application=>"bla", :group=>"gr1", :pid_file=>"2.pid"}}}}}}
    end

    it "double with_server in a group" do
      stub(Eye::Local).host{ "server1" }

      conf = <<-E
        Eye.application("bla") do
          process("1"){ pid_file "1.pid" }

          with_server "server1" do
            process("2"){ pid_file "2.pid" }
          end
        end
      E

      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :groups=>{"__default__"=>{:name=>"__default__", :application=>"bla", :processes=>{"1"=>{:name=>"1", :application=>"bla", :group=>"__default__", :pid_file=>"1.pid"}, "2"=>{:name=>"2", :application=>"bla", :group=>"__default__", :pid_file=>"2.pid"}}}}}}
    end

    it "with scoped" do
      stub(Eye::Local).host{ "server1" }

      conf = <<-E
        Eye.application("bla") do
          process("1"){ pid_file "1.pid" }

          scoped do
            process("2"){ pid_file "2.pid" }
          end
        end
      E

      Eye::Dsl.parse_apps(conf).should == {"bla" => {:name=>"bla", :groups=>{"__default__"=>{:name=>"__default__", :application=>"bla", :processes=>{"1"=>{:name=>"1", :application=>"bla", :group=>"__default__", :pid_file=>"1.pid"}, "2"=>{:name=>"2", :application=>"bla", :group=>"__default__", :pid_file=>"2.pid"}}}}}}
    end

  end

end