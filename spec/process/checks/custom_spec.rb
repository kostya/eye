require File.dirname(__FILE__) + '/../../spec_helper'

describe "Custom checks" do
  before :each do
    @c = Eye::Controller.new
  end

  describe "meaningless check" do
    before :each do
      conf = <<-D
        class CustomCheck < Eye::Checker::Custom
          param :below, [Fixnum, Float], true

          def initialize(*args)
            super
            @a = [true, true, false, false, false]
          end

          def get_value
            @a.shift
          end

          def good?(value)
            value
          end
        end

        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            checks :custom_check, :times => [1, 3], :below => 80, :every => 2
          end
        end
    D
      with_temp_file(conf){ |f| @c.load(f) }
      sleep 3
      @process = @c.process_by_name("1")
      @process.watchers.keys.should == [:check_alive, :check_custom_check]
    end

    it "should not restart" do
      dont_allow(@process).schedule(:restart)
      sleep 4
    end

    it "should restart" do
      proxy(@process).schedule(:restart, is_a(Eye::Reason))
      sleep 6
    end
  end

  describe "monitor touch file and stop the process and remove the file" do
    before :each do
      conf = <<-D
        class TouchFile < Eye::Checker::Custom
          param :file, [String], true

          def get_value
            !File.exists?(file)
          end
        end

        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true

            check :touch_file, :every => 3.seconds, :fire => :stop, :file => "#{C.tmp_file}"
            trigger :state, :event => :stopped, :do => ->{ File.delete("#{C.tmp_file}") }
          end
        end
    D
      with_temp_file(conf){ |f| @c.load(f) }
      sleep 3
      @process = @c.process_by_name("1")
    end

    it "should work" do
      @process.state_name.should == :up

      # doing touch file
      File.open(C.tmp_file, 'w')

      # sleep enougth
      sleep 5

      @process.state_name.should == :unmonitored

      File.exists?(C.tmp_file).should == false
    end
  end

end