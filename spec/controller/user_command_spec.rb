require File.dirname(__FILE__) + '/../spec_helper'

describe "Controller user_command" do
  subject { Eye::Controller.new }

  it "should execute string cmd" do
    cfg = <<-D
      Eye.application("app") do
        process("proc") do
          pid_file "#{C.p1_pid}"
          start_command "sleep 10"
          daemonize!
          start_grace 0.3

          command :abcd, "touch #{C.tmp_file}"
        end
      end
    D

    subject.load_content(cfg)
    sleep 0.5

    File.exists?(C.tmp_file).should == false
    subject.command('user_command', 'abcd', 'proc')
    sleep 0.5
    File.exists?(C.tmp_file).should == true
  end

  it "should execute signals cmd" do

    cfg = <<-D
      Eye.application("app") do
        process("proc") do
          pid_file "#{C.p1_pid}"
          start_command "sleep 10"
          daemonize!
          start_grace 0.3

          command :abcd, [:quit, 0.2, :term, 0.1, :kill]
        end
      end
    D

    subject.load_content(cfg)
    sleep 0.5

    @process = subject.process_by_name("proc")
    Eye::System.pid_alive?(@process.pid).should == true

    subject.command('user_command', 'abcd', 'app')
    sleep 0.7

    Eye::System.pid_alive?(@process.pid).should == false
  end

end
