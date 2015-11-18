require File.dirname(__FILE__) + '/../../spec_helper'

describe "Flapping retry" do
  before :each do
    @c = C.p1.merge(
      :triggers => C.flapping(:times => 2, :within => 3),
      :start_grace => 0.1, # for fast flapping
      :stop_grace => 0,
      :start_command => C.p1[:start_command] + " -r"
    )
  end

  it "flapping than wait for interval and try again" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3,
      :retry_in => 5.seconds)))
    @process.schedule :start

    sleep 18

    h = @process.states_history

    # был в unmonitored
    h.shift[:state].should == :unmonitored

    # должен попытаться подняться два раза,
    h.shift(6)

    # затем перейти в unmonitored с причиной flapping
    flapp1 = h.shift
    flapp1[:state].should == :unmonitored
    flapp1[:reason].to_s.should == 'flapping'

    # затем снова попыться подняться два раза
    h.shift(6)

    # и снова перейти в unmonitored с причиной flapping
    flapp2 = h.shift
    flapp2[:state].should == :unmonitored
    flapp2[:reason].to_s.should == 'flapping'

    # интервал между переходами во flapping должен быть больше 8 сек
    (flapp2[:at] - flapp1[:at]).should > 5.seconds

    # тут снова должен пытаться подниматься так как нет лимитов
    h.should_not be_blank
  end

  it "flapping retry 1 times with retry_times = 1" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3,
      :retry_in => 5.seconds, :retry_times => 1)))
    @process.schedule :start

    sleep 18

    h = @process.states_history

    # был в unmonitored
    h.shift[:state].should == :unmonitored

    # должен попытаться подняться два раза,
    h.shift(6)

    # затем перейти в unmonitored с причиной flapping
    flapp1 = h.shift
    flapp1[:state].should == :unmonitored
    flapp1[:reason].to_s.should == 'flapping'

    # затем снова попыться подняться два раза
    h.shift(6)

    # и снова перейти в unmonitored с причиной flapping
    flapp2 = h.shift
    flapp2[:state].should == :unmonitored
    flapp2[:reason].to_s.should == 'flapping'

    # интервал между переходами во flapping должен быть больше 8 сек
    (flapp2[:at] - flapp1[:at]).should > 5.seconds

    # все финал
    h.should be_blank
  end

  it "flapping than manually doing something, should not retry" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3,
      :retry_in => 5.seconds)))
    @process.schedule :start

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
    flapp1[:reason].to_s.should == 'flapping'

    # затем его руками переводят в unmonitored
    unm = h.shift
    unm[:state].should == :unmonitored
    unm[:reason].to_s.should == 'unmonitor by user'

    # все финал
    h.should be_blank
  end

  it "without retry_in" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 3)))
    @process.schedule :start

    sleep 10

    h = @process.states_history

    # был в unmonitored
    h.shift[:state].should == :unmonitored

    # должен попытаться подняться два раза,
    h.shift(6)

    # затем перейти в unmonitored с причиной flapping
    flapp1 = h.shift
    flapp1[:state].should == :unmonitored
    flapp1[:reason].to_s.should == 'flapping'

    # все финал
    h.should be_blank
  end

  describe "reretry_in" do
    it "reretry_in" do
      @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 2.second,
        :retry_in => 2.seconds, :retry_times => 1, :reretry_in => 3.seconds)))
      @process.schedule :start

      sleep 25
      reasons = @process.schedule_history.map { |h| h[:reason].to_s }
      reasons.count { |r| r == "retry start after flapping" }.should >= 2
      reasons.count { |r| r == "reretry start after flapping" }.should >= 2
    end
    it "reretry_in, reretry_times" do
      @process = process(@c.merge(:triggers => C.flapping(:times => 2, :within => 2.second,
        :retry_in => 2.seconds, :retry_times => 1, :reretry_in => 3.seconds, :reretry_times => 1)))
      @process.schedule :start

      sleep 25
      reasons = @process.schedule_history.map { |h| h[:reason].to_s }
      reasons.count { |r| r == "retry start after flapping" }.should == 2
      reasons.count { |r| r == "reretry start after flapping" }.should == 1
    end
  end
end
