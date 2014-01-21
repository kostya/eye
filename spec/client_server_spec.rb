require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::Client, Eye::Server" do

  before :each do
    @socket_path = C.socket_path
    @client = Eye::Client.new(@socket_path)
    @server = Eye::Server.new(@socket_path)
  end

  after :each do
    @server.terminate
  end

  it "client command, should send to controller" do
    mock(Eye::Control).command('restart', 'samples'){ :command_sent }
    mock(Eye::Control).command('stop'){ :command_sent2 }
    @server.async.run
    sleep 0.1

    @client.command('restart', 'samples').should == :command_sent
    @client.command('stop').should == :command_sent2
  end

  it "another spec works too" do
    mock(Eye::Control).command('stop'){ :command_sent2 }
    @server.async.run
    sleep 0.1

    @client.command('stop').should == :command_sent2
  end

  it "if server already listen should recreate" do
    mock(Eye::Control).command('stop'){ :command_sent2 }
    @server.async.run
    sleep 0.1
    @server2 = Eye::Server.new(@socket_path)
    @server2.async.run
    sleep 0.1
    @client.command('stop').should == :command_sent2
  end

  it "if error server should be alive" do
    @server.async.run
    sleep 0.1
    @client.attempt_command('trash').should == :corrupted_data
    @server.alive?.should be_true
  end

end
