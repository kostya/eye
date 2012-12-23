# -*- encoding : utf-8 -*-
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
    mock(Eye::Control).command('restart', 'samples'){ :command_sended }
    mock(Eye::Control).command('stop'){ :command_sended2 }
    @server.run!
    sleep 0.1
    
    @client.command('restart', 'samples').should == :command_sended
    @client.command('stop').should == :command_sended2
  end  

  it "another spec works too" do
    mock(Eye::Control).command('stop'){ :command_sended2 }
    @server.run!
    sleep 0.1
    
    @client.command('stop').should == :command_sended2
  end  

end
