require File.dirname(__FILE__) + '/../../spec_helper'

describe "Flapping" do
  before :each do
    @c = C.p1.merge(      
      :triggers => C.flapping(:times => 4, :within => 10)
    )    
  end

  it "should create trigger from config" do
    start_ok_process(@c)

    triggers = @process.triggers
    triggers.size.should == 1

    triggers.first.class.should == Eye::Trigger::Flapping
    triggers.first.within.should == 10
    triggers.first.times.should == 4
  end

  it "should check speedy flapping by default" do
    start_ok_process(C.p1)

    triggers = @process.triggers
    triggers.size.should == 1

    triggers.first.class.should == Eye::Trigger::Flapping
    triggers.first.within.should == 10
    triggers.first.times.should == 10
  end

  it "process flapping" do
    @process = process(@c.merge(:start_command => @c[:start_command] + " -r"))
    @process.start!

    stub(@process).notify(:warn, anything)
    mock(@process).notify(:crit, anything)

    sleep 13

    # check flapping happens here

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []
    @process.states_history.states.last(2).should == [:down, :unmonitored]
  end

  it "process flapping emulate with kill" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 3, :within => 7)))

    @process.start

    3.times do
      die_process!(@process.pid)
      sleep 3
    end

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []

    # ! should switched to unmonitored from down status
    @process.states_history.states.last(2).should == [:down, :unmonitored]
  end

  it "process flapping, and then send to start and fast kill, should ok started" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 3, :within => 15)))

    @process.start

    3.times do
      die_process!(@process.pid)
      sleep 3
    end

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []

    @process.start
    @process.state_name.should == :up

    die_process!(@process.pid)
    sleep 4
    @process.state_name.should == :up
  end

  it "flapping not happens" do
    @process = process(@c)
    @process.start!

    proxy(@process).schedule(:start, anything)
    proxy(@process).schedule(:check_crash, anything)
    dont_allow(@process).schedule(:unmonitor)

    sleep 2

    2.times do
      die_process!(@process.pid)
      sleep 3
    end

    sleep 2

    @process.state_name.should == :up    
  end

  describe "retry_in, retry_times" do
    before :each do
      @c = C.p1.merge(
        :triggers => C.flapping(:times => 2, :within => 3),
        :start_grace => 0.1, # for fast flapping
        :stop_grace => 0,
        :start_command => @c[:start_command] + " -r"
      )    
    end

    it "flapping than wait for interval and try again" do
      @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3, 
        :retry_in => 5.seconds)))
      @process.start!

      sleep 18

      h = @process.states_history

      # был в unmonitored
      h.shift[:state].should == :unmonitored

      # должен попытаться подняться два раза,
      h.shift(6)

      # затем перейти в unmonitored с причиной flapping
      flapp1 = h.shift
      flapp1[:state].should == :unmonitored
      flapp1[:reason].should == 'flapping'

      # затем снова попыться подняться два раза
      h.shift(6)

      # и снова перейти в unmonitored с причиной flapping
      flapp2 = h.shift
      flapp2[:state].should == :unmonitored
      flapp2[:reason].should == 'flapping'

      # интервал между переходами во flapping должен быть больше 8 сек
      (flapp2[:at] - flapp1[:at]).should > 5.seconds

      # тут снова должен пытаться подниматься так как нет лимитов
      h.should_not be_blank
    end

    it "flapping retry 1 times with retry_times = 1" do
      @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3, 
        :retry_in => 5.seconds, :retry_times => 1)))
      @process.start!

      sleep 18

      h = @process.states_history

      # был в unmonitored
      h.shift[:state].should == :unmonitored

      # должен попытаться подняться два раза,
      h.shift(6)

      # затем перейти в unmonitored с причиной flapping
      flapp1 = h.shift
      flapp1[:state].should == :unmonitored
      flapp1[:reason].should == 'flapping'

      # затем снова попыться подняться два раза
      h.shift(6)

      # и снова перейти в unmonitored с причиной flapping
      flapp2 = h.shift
      flapp2[:state].should == :unmonitored
      flapp2[:reason].should == 'flapping'

      # интервал между переходами во flapping должен быть больше 8 сек
      (flapp2[:at] - flapp1[:at]).should > 5.seconds

      # все финал
      h.should be_blank
    end

    it "flapping than manually doing something, should not retry" do
      @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3, 
        :retry_in => 5.seconds)))
      @process.start!

      sleep 6
      @process.send_command :unmonitor
      sleep 9

      h = @process.states_history

      # был в unmonitored
      h.shift[:state].should == :unmonitored

      # должен попытаться подняться два раза,
      h.shift(6)

      # затем перейти в unmonitored с причиной flapping
      flapp1 = h.shift
      flapp1[:state].should == :unmonitored
      flapp1[:reason].should == 'flapping'

      # затем его руками переводят в unmonitored
      unm = h.shift
      unm[:state].should == :unmonitored
      unm[:reason].should == 'unmonitor by user'

      # все финал
      h.should be_blank
    end

    it "without retry_in" do
      @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3)))
      @process.start!

      sleep 10

      h = @process.states_history

      # был в unmonitored
      h.shift[:state].should == :unmonitored

      # должен попытаться подняться два раза,
      h.shift(6)

      # затем перейти в unmonitored с причиной flapping
      flapp1 = h.shift
      flapp1[:state].should == :unmonitored
      flapp1[:reason].should == 'flapping'

      # все финал
      h.should be_blank
    end

  end

end