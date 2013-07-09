require File.dirname(__FILE__) + '/../spec_helper'

describe "options spec" do
  describe "http" do
    subject{ Eye::Controller.new }
    let(:uri){ URI.parse("http://127.0.0.1:#{port1}/") }
    let(:uri2){ URI.parse("http://127.0.0.1:#{port2}/") }

    it "load config with http enable" do
      expect{ Net::HTTP.get(uri) }.to raise_error(Errno::ECONNREFUSED)

      subject.load(fixture("dsl/http/http1.eye"))
      Net::HTTP.get(uri).should == Eye::ABOUT
    end

    it "load config with http enable then disable" do
      subject.load(fixture("dsl/http/http1.eye"))
      Net::HTTP.get(uri).should == Eye::ABOUT

      subject.load(fixture("dsl/http/http2.eye"))
      expect{ Net::HTTP.get(uri) }.to raise_error(Errno::ECONNREFUSED)
    end

    it "load config with http enable then change port" do
      subject.load(fixture("dsl/http/http1.eye"))
      Net::HTTP.get(uri).should == Eye::ABOUT

      subject.load(fixture("dsl/http/http3.eye"))
      expect{ Net::HTTP.get(uri) }.to raise_error(Errno::ECONNREFUSED)
      Net::HTTP.get(uri2).should == Eye::ABOUT
    end

    it "should not reconnect when load the same config" do
      subject.load(fixture("dsl/http/http1.eye")).should_be_ok
      Net::HTTP.get(uri).should == Eye::ABOUT

      dont_allow(subject).stop_http

      subject.load(fixture("dsl/http/http1.eye")).should_be_ok
      Net::HTTP.get(uri).should == Eye::ABOUT
    end

    it "load error should catch" do
      subject.load(fixture("dsl/http/http4.eye")).errors_count.should == 1
    end
  end

end