require File.dirname(__FILE__) + '/../spec_helper'

def chhttp(cfg = {})
  Eye::Checker.create(nil, {:type => :http, :every => 5.seconds,
        :times => 1, :url => "http://localhost:3000/", :kind => :success,
        :pattern => /OK/, :timeout => 2}.merge(cfg))
end

describe "Eye::Checker::Http" do

  after :each do
    FakeWeb.clean_registry
  end

  describe "get_value" do
    subject{ chhttp }

    it "initialize" do
      subject.instance_variable_get(:@kind).should == Net::HTTPSuccess
      subject.instance_variable_get(:@open_timeout).should == 3
      subject.instance_variable_get(:@read_timeout).should == 2
      subject.pattern.should == /OK/
    end

    it "without url" do
      expect{ chhttp(:url => nil).uri }.to raise_error
    end

    it "get_value" do
      FakeWeb.register_uri(:get, "http://localhost:3000/", :body => "Somebody OK")
      subject.get_value[:result].body.should == "Somebody OK"

      subject.human_value(subject.get_value).should == "200=0Kb"
    end

    it "get_value exception" do
      a = ""
      stub(subject).session{ a }
      stub(subject.session).start{ raise Timeout::Error, "timeout" }
      mes = RUBY_VERSION < '2.0' ? "Timeout<3.0,2.0>" : "ReadTimeout<2.0>"

      subject.get_value.should == {:exception => mes}
      subject.human_value(subject.get_value).should == mes
    end

    if defined?(Net::OpenTimeout)
      it "get_value OpenTimeout exception" do
        a = ""
        stub(subject).session{ a }
        stub(subject.session).start{ raise Net::OpenTimeout, "open timeout" }

        subject.get_value.should == {:exception => "OpenTimeout<3.0>"}
        subject.human_value(subject.get_value).should == "OpenTimeout<3.0>"
      end
    end

    it "get_value raised" do
      a = ""
      stub(subject).session{ a }
      stub(subject.session).start{ raise "something" }
      subject.get_value.should == {:exception => "Error<something>"}

      subject.human_value(subject.get_value).should == "Error<something>"
    end

  end

  describe "good?" do
    subject{ chhttp }

    it "good" do
      FakeWeb.register_uri(:get, "http://localhost:3000/", :body => "Somebody OK")
      subject.check.should == true
    end

    it "good pattern is string" do
      subject = chhttp(:pattern => "OK")
      FakeWeb.register_uri(:get, "http://localhost:3000/", :body => "Somebody OK")
      subject.check.should == true
    end

    it "bad pattern" do
      FakeWeb.register_uri(:get, "http://localhost:3000/", :body => "Somebody bad")
      subject.check.should == false
    end

    it "bad pattern string" do
      subject = chhttp(:pattern => "OK")
      FakeWeb.register_uri(:get, "http://localhost:3000/", :body => "Somebody bad")
      subject.check.should == false
    end

    it "not 200" do
      FakeWeb.register_uri(:get, "http://localhost:3000/bla", :body => "Somebody OK", :status => [500, 'err'])
      subject.check.should == false
    end

    it "without patter its ok" do
      subject = chhttp(:pattern => nil)
      FakeWeb.register_uri(:get, "http://localhost:3000/", :body => "Somebody OK")
      subject.check.should == true
    end
  end

  describe "validates" do
    it "ok" do
      Eye::Checker.validate!({:type => :http, :every => 5.seconds,
        :times => 1, :url => "http://localhost:3000/", :kind => :success,
        :pattern => /OK/, :timeout => 2})
    end

    it "without param url" do
      expect{ Eye::Checker.validate!({:type => :http, :every => 5.seconds,
        :times => 1, :kind => :success,
        :pattern => /OK/, :timeout => 2}) }.to raise_error(Eye::Dsl::Validation::Error)
    end

    it "bad param timeout" do
      expect{ Eye::Checker.validate!({:type => :http, :every => 5.seconds,
        :times => 1, :kind => :success, :url => "http://localhost:3000/",
        :pattern => /OK/, :timeout => :fix}) }.to raise_error(Eye::Dsl::Validation::Error)
    end
  end

end