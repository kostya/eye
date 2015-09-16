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
      @c.load_content(conf)
      sleep 3
      @process = @c.process_by_name("1")
      @process.watchers.keys.should == [:check_alive, :check_identity, :check_custom_check]
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
            !File.exist?(file)
          end
        end

        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true

            check :touch_file, :every => 3.seconds, :fires => [:stop], :file => "#{C.tmp_file}"
            trigger :transition, :event => :stopped, :do => ->{ ::File.delete("#{C.tmp_file}") }
          end
        end
    D
      @c.load_content(conf)
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

      File.exist?(C.tmp_file).should == false
    end
  end

  describe "catch exceptions" do
    before :each do
      @app = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            check :cust1, :every => 1.seconds
          end
        end
      D
    end

    it "when raised in initialize" do
      conf = <<-D
        class Cust1 < Eye::Checker::Custom
          def initialize(*a); super; raise :jop; end
          def get_value; 1; end
          def good?(v); v; end
        end
        #{@app}
      D
      @c.load_content(conf)
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }


      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "when raised in get_value" do
      conf = <<-D
        class Cust1 < Eye::Checker::Custom
          def initialize(*a); super; end
          def get_value; raise :jop; end
          def good?(v); v; end
        end
        #{@app}
      D
      @c.load_content(conf)
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "when raised in good?" do
      conf = <<-D
        class Cust1 < Eye::Checker::Custom
          def initialize(*a); super; end
          def get_value; 1; end
          def good?(v); raise :jop; end
        end
        #{@app}
      D
      @c.load_content(conf)
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "when raised in good? and NoMethodError" do
      conf = <<-D
        class Cust1 < Eye::Checker::Custom
          def initialize(*a); super; end
          def get_value; 1; end
          def good?(v); jop; end
        end
        #{@app}
      D
      @c.load_content(conf)
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "when raised in defer" do
      conf = <<-D
        class Cust1 < Eye::Checker::Custom
          def initialize(*a); super; end
          def get_value; 1; end
          def good?(v); defer{ jop }; end
        end
        #{@app}
      D
      @c.load_content(conf)
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

  end

end