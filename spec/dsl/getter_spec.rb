require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl getters" do

  it "should get param from scope with =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.start_timeout = 10.seconds
        app.stop_timeout = app.start_timeout
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :name => "bla"}}
  end

  it "should get param from scope without =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.start_timeout 10.seconds
        app.stop_timeout app.start_timeout
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :name => "bla"}}
  end

  it "should get param from auto scope" do
    conf = <<-E
      Eye.application("bla") do
        start_timeout 10.seconds
        stop_timeout start_timeout
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :name => "bla"}}
  end

  it "double =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.stdout = app.stderr = '1'
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :stdout => '1', :stderr => '1'}}
  end

  it "pure_getter" do
    conf = <<-E
      Eye.application("bla") do |app|
        start_timeout 11
        app.stop_timeout = app.get_start_timeout
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:start_timeout=>11, :stop_timeout=>11, :name => "bla"}}
  end

  it "env throught proxies" do
    conf = <<-E
      Eye.application("bla") do |app|
        env "A" => "1"

        group :blagr do |gr|
          env "A" => app.env['A'] + "2"

          process :blap do |p|
            pid_file '1'
            env "A" => gr.env['A'] + "3"

            start_command "ruby app:\#{app.name} gr:\#{gr.name} p:\#{p.name} \#{app.env} \#{gr.env} \#{p.env} \#{pid_file}"
          end
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", :environment=>{"A"=>"1"}, :groups=>{
        "blagr"=>{:name => "blagr", :application => "bla", :environment=>{"A"=>"12"}, :processes=>{
          "blap"=>{:environment=>{"A"=>"123"}, :group=>"blagr", :application=>"bla", :name=>'blap', :pid_file=>"1",
            :start_command=>"ruby app:bla gr:blagr p:blap {\"A\"=>\"1\"} {\"A\"=>\"12\"} {\"A\"=>\"123\"} 1"}}}}}}
  end

  it "getter full_name" do
    conf = <<-E
      Eye.application("bla") do
        env "A" => "\#{self.full_name}"

        group :blagr do
          env 'B' => "\#{self.full_name}"

          process :blap do
            env 'C' => "\#{self.full_name}"

            pid_file '1'
          end
        end

        process :blap2 do
          env 'D' => "\#{self.full_name}"
          pid_file "2"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", :environment=>{"A"=>"bla"}, :groups=>{
        "blagr"=>{:name => "blagr", :application => "bla", :environment=>{"A"=>"bla", "B"=>"bla:blagr"}, :processes=>{
          "blap"=>{:environment=>{"A"=>"bla", "B"=>"bla:blagr", "C"=>"bla:blagr:blap"}, :pid_file=>"1", :group=>"blagr", :application=>"bla", :name=>'blap'}}},
        "__default__"=>{:name => "__default__", :environment=>{"A"=>"bla"}, :application => "bla", :processes=>{
          "blap2"=>{:environment=>{"A"=>"bla", "D"=>"bla:blap2"}, :pid_file=>"2", :group=>"__default__", :application=>"bla", :name=>'blap2'}}}}}}
  end

  it "getting autodefined opts" do
    conf = <<-E
      Eye.app :bla do |app|
        env 'a' => 'b'

        group :blagr do |gr|
          process :blap do |pr|
            pid_file "/tmp/\#{pr.name}"

            env 'aa' => app.env['a']
            env 'ab' => app.env['b']
            env 'ga' => gr.env['a'] # here should be set 'b' from inherited app.env['a']
            env 'gb' => gr.env['b']
          end
        end
      end
    E

    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", :environment=>{"a"=>"b"}, :groups=>{
        "blagr"=>{:name => "blagr", :application => "bla", :environment=>{"a"=>"b"}, :processes=>{
          "blap"=>{:environment=>{"a"=>"b", "aa"=>"b", "ga"=>"b", "ab" => nil, "gb" => nil}, :pid_file=>"/tmp/blap", :group=>"blagr", :application=>"bla", :name=>'blap'}}}}}}
  end

  it "auto inherited opts" do
    conf = <<-E
      Eye.app :bla do |app|
        working_dir "/tmp"

        group :blagr do |gr|
          env 'A' => "\#{app.working_dir}"

          process :blap do |p|
            pid_file "\#{p.working_dir}/1.pid"
          end
        end
      end
    E

    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name => "bla", :working_dir=>"/tmp", :groups=>{
        "blagr"=>{:name => "blagr", :application => "bla", :working_dir=>"/tmp", :environment=>{"A"=>"/tmp"}, :processes=>{
          "blap"=>{:working_dir=>"/tmp", :environment=>{"A"=>"/tmp"}, :pid_file=>"/tmp/1.pid", :group=>"blagr", :application=>"bla", :name=>'blap'}}}}}}
  end

  it "parent spec" do
    conf = <<-E
      Eye.application("bla") do |app|
        working_dir "/tmp"
        group :blagr do
          self.working_dir = "\#{self.parent.working_dir}/1"
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {"bla" => {:name => "bla", :working_dir=>"/tmp", :groups=>{"blagr"=>{:name => "blagr", :application => "bla", :working_dir=>"/tmp/1"}}}}
  end

  describe "back links (application, group)" do
    it "process back links" do
      conf = <<-E
        Eye.application("bla") do |app|
          working_dir "/tmp"

          process :p1 do
            start_command "ruby -t '\#{self.application.name}.\#{self.group.name}'"
            pid_file "p1"
          end

          group :blagr do
            process :p2 do
              start_command "ruby -t '\#{self.app.name}.\#{self.group.name}'"
              pid_file "p2"
            end

            process :p3 do
              start_command "ruby -t '\#{self.group.app.name}.\#{self.group.name}'"
              pid_file "p3"
            end

          end
        end
      E
      Eye::Dsl.parse_apps(conf).should == {
        "bla" => {:name=>"bla", :working_dir=>"/tmp", :groups=>{
          "__default__"=>{:name=>"__default__", :working_dir=>"/tmp", :application=>"bla", :processes=>{
            "p1"=>{:name=>"p1", :working_dir=>"/tmp", :application=>"bla", :group=>"__default__",
              :start_command=>"ruby -t 'bla.__default__'", :pid_file=>"p1"}}},
          "blagr"=>{:name=>"blagr", :working_dir=>"/tmp", :application=>"bla", :processes=>{
            "p2"=>{:name=>"p2", :working_dir=>"/tmp", :application=>"bla", :group=>"blagr",
              :start_command=>"ruby -t 'bla.blagr'", :pid_file=>"p2"},
            "p3"=>{:name=>"p3", :working_dir=>"/tmp", :application=>"bla", :group=>"blagr",
              :start_command=>"ruby -t 'bla.blagr'", :pid_file=>"p3"}}}}}}
    end

    it "group back links" do
      conf = <<-E
        Eye.application("bla") do |app|
          working_dir "/tmp"

          env "a" => "\#{self.name}"

          group :blagr do |gr|
            env "b" => "\#{gr.application.name}"
            env "c" => "\#{gr.app.name}"
            env "d" => "\#{gr.parent.name}"
          end
        end
      E
      Eye::Dsl.parse_apps(conf).should == {
        "bla" => {:name=>"bla", :working_dir=>"/tmp", :environment=>{"a"=>"bla"}, :groups=>{
          "blagr"=>{:name=>"blagr", :working_dir=>"/tmp",
            :environment=>{"a"=>"bla", "b"=>"bla", "c"=>"bla", "d"=>"bla"}, :application=>"bla"}}}}
    end

  end

end
