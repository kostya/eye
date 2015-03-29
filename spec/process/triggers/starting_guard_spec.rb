require File.dirname(__FILE__) + '/../../spec_helper'

describe "Trigger StartingGuard" do
  def process(trigger)
    @c = Eye::Controller.new
    cfg = <<-D
      Eye.application("bla") do
        working_dir "#{C.sample_dir}"
        process("1") do
          pid_file "#{C.p1_pid}"
          start_command "sleep 30"
          daemonize true
          #{trigger}
          start_grace 0.5
        end
      end
    D

    @c.load_content(cfg)
    @process = @c.process_by_name("1")
  end

  describe "run at 3 time, skip first 2 times" do
    before :each do
      process(<<-T)
        trigger :starting_guard, every: 3.seconds, should: -> {
          @times ||= 0
          @times += 1
          @times == 3
        }
      T
    end

    it "should be up" do
      sleep 5
      @process.state_name.should == :unmonitored
      sleep 4
      @process.state_name.should == :up
      @process.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :up]
    end
  end

  describe "when always false process, never started" do
    before :each do
      process("trigger :starting_guard, every: 0.5, should: ->{ false }")
    end

    it "should be up" do
      sleep 5
      @process.state_name.should_not == :up
      sleep 4
      @process.state_name.should_not == :up
      @process.schedule_history.states.count(:conditional_start).should > 15
    end
  end

  describe "with times" do
    before :each do
      process("trigger :starting_guard, every: 0.5, times: 6, should: ->{ false }")
    end

    it "should be up" do
      sleep 4
      @process.state_name.should == :unmonitored
      @process.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored]
      sleep 4
      @process.state_name.should == :unmonitored
      @process.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored]
    end
  end

  describe "with times, reretry_in" do
    before :each do
      process("trigger :starting_guard, every: 0.5, times: 6, retry_in: 2.seconds, should: ->{ false }")
    end

    it "should be up" do
      sleep 8
      @process.state_name.should == :unmonitored
      @process.states_history.states.count { |c| c == :starting }.should <= 12
    end
  end

  describe "with times, retry_in, retry_times" do
    before :each do
      process("trigger :starting_guard, every: 0.5, times: 6, retry_in: 1.seconds, retry_times: 2, should: ->{ false }")
    end

    it "should be up" do
      sleep 13
      @process.state_name.should == :unmonitored
      @process.states_history.states.count { |c| c == :starting }.should <= 18
    end
  end

  describe "after retry process was unmonitored by hands, should not retry" do
    before :each do
      process("trigger :starting_guard, every: 1, should: ->{ false }")
    end

    it "should be up" do
      sleep 3
      @process.state_name.should_not == :up
      @process.send_command('unmonitor')
      @process.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :unmonitored]
      sleep 3
      @process.state_name.should == :unmonitored
      @process.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :unmonitored, :starting, :unmonitored, :unmonitored]
    end
  end

  describe "should not block actor, use defer" do
    before :each do
      process("trigger :starting_guard, every: 1, should: ->{ x = `sleep 5 && echo 1`; x.to_i } ")
    end

    it "should be up" do
      should_spend(3) do
        sleep 3
        @process.state_name.should == :starting
      end
    end
  end

  describe "should reset retry_count" do
    before :each do
      process("trigger :starting_guard, every: 0.5, times: 6, should: ->{ @x ||= 0; @x += 1; if @x == 5; @x = 0; end } ")
    end

    it "should be up" do
      sleep 4
      @process.state_name.should == :up

      @process.schedule :restart
      sleep 4
      @process.state_name.should == :up
    end
  end

end
