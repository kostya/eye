require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl::Chain" do

  it "should understand chain options" do
    conf = <<-E
      Eye.application("bla") do
        chain :grace => 5.seconds

        process("3") do
          pid_file "3"
        end

        group :yy do
        end
      end
    E

    h = {
      "bla" => {
        :name=>"bla",
        :chain=>{:start=>{:grace=>5, :action=>:start}, :restart=>{:grace=>5, :action=>:restart}},
        :groups=>{
          "__default__"=>{
            :name=>"__default__",
            :chain=>{:start=>{:grace=>5, :action=>:start}, :restart=>{:grace=>5, :action=>:restart}},
            :application=>"bla",
            :processes=>{
              "3"=>{
                :name=>"3",
                :application=>"bla",
                :group=>"__default__",
                :pid_file=>"3"}}},
          "yy"=>{
            :name=>"yy",
            :chain=>{:start=>{:grace=>5, :action=>:start}, :restart=>{:grace=>5, :action=>:restart}},
            :application=>"bla"}}}
    }

    Eye::Dsl.parse_apps(conf).should == h
  end

  it "1 inner group have" do
    conf = <<-E
      Eye.application("bla") do
        group "gr1" do
          chain :grace => 5.seconds
        end

        process("p1"){pid_file('1')}
      end
    E

    h = {
      "bla" => {:name => "bla",
        :groups=>{
          "gr1"=>{:name => "gr1", :application => "bla",
            :chain=>{:start=>{:grace=>5, :action=>:start},
              :restart=>{:grace=>5, :action=>:restart}}},
          "__default__"=>{:name => "__default__", :application => "bla",
            :processes=>{"p1"=>{:pid_file=>"1", :application=>"bla", :group=>"__default__", :name=>"p1"}}}}}}

    Eye::Dsl.parse_apps(conf).should == h
  end

  it "1 group have, 1 not" do
    conf = <<-E
      Eye.application("bla") do
        group "gr1" do
          working_dir "/tmp"
          chain :grace => 5.seconds
        end

        group("gr2"){
          working_dir '/tmp'
        }
      end
    E

    h = {
      "bla" => {:name => "bla",
        :groups=>{
          "gr1"=>{:name => "gr1", :application => "bla",
            :working_dir=>"/tmp",
            :chain=>{:start=>{:grace=>5, :action=>:start}, :restart=>{:grace=>5, :action=>:restart}}},
          "gr2"=>{:working_dir=>"/tmp", :name => "gr2", :application => "bla"}}}}

    Eye::Dsl.parse_apps(conf).should == h
  end

  it "one option" do
    conf = <<-E
      Eye.application("bla") do
        chain :grace => 5.seconds, :action => :start, :type => :async

        process("3") do
          pid_file "3"
        end
      end
    E

    h = {"bla" => {:name => "bla",
      :chain=>{
        :start=>{:grace=>5, :action=>:start, :type=>:async}},
      :groups=>{
        "__default__"=>{:name => "__default__", :application => "bla",
          :chain=>{:start=>{:grace=>5, :action=>:start, :type=>:async}},
          :processes=>{"3"=>{:pid_file=>"3", :application=>"bla", :group=>"__default__", :name=>"3"}}}}}}

    Eye::Dsl.parse_apps(conf).should == h
  end

  it "group can rewrite part of options" do
    conf = <<-E
      Eye.application("bla") do
        chain :grace => 5.seconds

        group "gr" do
          chain :grace => 10.seconds, :action => :start, :type => :sync

          process("3") do
            pid_file "3"
          end
        end
      end
    E

    h = {"bla" => {:name => "bla",
      :chain=>{
        :start=>{:grace=>5, :action=>:start},
        :restart=>{:grace=>5, :action=>:restart}},
      :groups=>{
        "gr"=>{:name => "gr", :application => "bla",
          :chain=>{
            :start=>{:grace=>10, :action=>:start, :type=>:sync},
            :restart=>{:grace=>5, :action=>:restart}},
        :processes=>{"3"=>{:pid_file=>"3", :application=>"bla", :group=>"gr", :name=>"3"}}}}}}

    Eye::Dsl.parse_apps(conf).should == h
  end


end