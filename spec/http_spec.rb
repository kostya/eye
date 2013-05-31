require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::Http" do
  let(:uri){ URI.parse("http://127.0.0.1:33344/") }

  it "should up and down" do
    app = Eye::Http.new(uri.host, uri.port)

    expect{ Net::HTTP.get(uri) }.to raise_error(Errno::ECONNREFUSED)

    app.start
    sleep 0.5
    Net::HTTP.get(uri).should == Eye::ABOUT

    app.stop
    sleep 0.5
    expect{ Net::HTTP.get(uri) }.to raise_error(Errno::ECONNREFUSED)

    app.start
    sleep 0.5
    Net::HTTP.get(uri).should == Eye::ABOUT

    app.stop
  end
end
