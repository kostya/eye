require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl getters" do

  it "should get param from scope with =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.start_timeout = 10.seconds
        app.stop_timeout = app.start_timeout
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :groups => {}}}
  end

  it "should get param from scope without =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.start_timeout 10.seconds
        app.stop_timeout app.start_timeout
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :groups => {}}}
  end

  it "should get param from auto scope" do
    conf = <<-E
      Eye.application("bla") do
        start_timeout 10.seconds
        stop_timeout start_timeout
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :groups => {}}}
  end

  it "double =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.stdout = app.stderr = '1'
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:stdout => '1', :stderr => '1', :groups => {}}}
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
    Eye::Dsl.load(conf).should == {
      "bla" => {:environment=>{"A"=>"1"}, :groups=>{
        "blagr"=>{:environment=>{"A"=>"12"}, :processes=>{
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
    Eye::Dsl.load(conf).should == {
      "bla" => {:environment=>{"A"=>""}, :groups=>{
        "blagr"=>{:environment=>{"A"=>"", "B"=>""}, :processes=>{
          "blap"=>{:environment=>{"A"=>"", "B"=>"", "C"=>""}, :pid_file=>"1", :group=>"blagr", :application=>"bla", :name=>'blap'}}}, 
        "__default__"=>{:processes=>{
          "blap2"=>{:environment=>{"A"=>"", "D"=>""}, :pid_file=>"2", :group=>"__default__", :application=>"bla", :name=>'blap2'}}}}}}
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

    Eye::Dsl.load(conf).should == {
      "bla" => {:environment=>{"a"=>"b"}, :groups=>{
        "blagr"=>{:environment=>{"a"=>"b"}, :processes=>{
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

    Eye::Dsl.load(conf).should == {
      "bla" => {:working_dir=>"/tmp", :groups=>{
        "blagr"=>{:working_dir=>"/tmp", :environment=>{"A"=>"/tmp"}, :processes=>{
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
    Eye::Dsl.load(conf).should == {"bla" => {:working_dir=>"/tmp", :groups=>{"blagr"=>{:working_dir=>"/tmp/1", :processes => {}}}}}
  end

end