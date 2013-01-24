require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl getters" do

  it "should get param from scope with =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.start_timeout = 10.seconds
        app.stop_timeout = app.start_timeout
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :groups=>{}}}
  end

  it "should get param from scope without =" do
    conf = <<-E
      Eye.application("bla") do |app|
        app.start_timeout 10.seconds
        app.stop_timeout app.start_timeout
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :groups=>{}}}
  end

  it "should get param from auto scope" do
    conf = <<-E
      Eye.application("bla") do
        start_timeout 10.seconds
        stop_timeout start_timeout
      end
    E
    Eye::Dsl.load(conf).should == {"bla" => {:start_timeout=>10, :stop_timeout=>10, :groups=>{}}}
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
    Eye::Dsl.load(conf).should == {"bla" => {:environment=>{"A"=>"1"}, :groups=>{
      "blagr"=>{:environment=>{"A"=>"12"}, 
        :processes=>{
          "blap"=>{
            :environment=>{"A"=>"123"}, 
            :pid_file=>"1", 
            :start_command=>"ruby app:bla gr:blagr p:blap {\"A\"=>\"1\"} {\"A\"=>\"12\"} {\"A\"=>\"123\"} 1", 
            :application=>"bla", 
            :group=>"blagr", 
            :name=>"blap"}}}}}}
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
        end
      end
    E
    Eye::Dsl.load(conf).should == {}
  end

  it "getting autodefined opts" do
    conf = <<-E
      Eye.app :bla do |app|
        env 'a' => 'b'

        group :blagr do |gr|
          process :blap do |p|
            pid_file "/tmp/\#{p.name}"

            env 'aa' => app.env['a']
            env 'ga' => gr.env['a'] # here should be set 'b' from inherited app.env['a']
          end
        end
      end
    E

    Eye::Dsl.load(conf).should == {}
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

    Eye::Dsl.load(conf).should == {}
  end

end