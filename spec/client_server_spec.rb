require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::Client, Eye::Server" do

  before :each do
    @socket_path = C.socket_path
    @client = Eye::Client.new(@socket_path)
    @server = Eye::Server.new(@socket_path)

    @server.async.run
    sleep 0.1
  end

  after :each do
    @server.terminate
  end

  it "client command, should send to controller" do
    mock(Eye::Control).command('restart', 'samples', {}){ :command_sent }
    mock(Eye::Control).command(:stop, {}){ :command_sent2 }
    @client.execute(command: 'restart', args: %w{samples}).should == :command_sent
    @client.execute(command: :stop).should == :command_sent2
  end

  it "another spec works too" do
    mock(Eye::Control).command('stop', {}){ :command_sent2 }
    @client.execute(command: 'stop').should == :command_sent2
  end

  it "if server already listen should recreate" do
    mock(Eye::Control).command('stop', {}){ :command_sent2 }
    @server2 = Eye::Server.new(@socket_path)
    @server2.async.run
    sleep 0.1
    @client.execute(command: 'stop').should == :command_sent2
  end

  it "if error server should be alive" do
    @client.send(:attempt_command, 'trash', 1).should == :corrupted_data
    @server.alive?.should == true
  end

  it "big message, to pass env variables in future" do
    a = "a" * 10000
    mock(Eye::Control).command('stop', a, {}){ :command_sent2 }
    @client.execute(command: 'stop', args: [a]).should == :command_sent2
  end

  it "big message, to answer" do
    a = "a" * 50000
    mock(Eye::Control).command('stop', {}){ a }
    @client.execute(command: 'stop').size.should == 50000
  end

  # TODO, remove in 1.0
  describe "old message format" do
    it "ok message" do
      mock(Eye::Control).command('restart', 'samples', {}){ :command_sent }
      @client.send(:attempt_command, Marshal.dump(%w{restart samples}), 1).should == :command_sent
    end
  end

end
