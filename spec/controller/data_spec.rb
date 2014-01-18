require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Controller data spec" do
  subject{ Eye::Controller.new }
  before { subject.load(fixture("dsl/load.eye")) }

  it "info_data" do
    res = subject.command(:info_data)
    st = res[:subtree]
    st.size.should == 2
    p = st[1][:subtree][0][:subtree][0]
    p.should include(:name=>"z1", :state=>"unmonitored",
      :type=>:process, :resources=>{:memory=>nil, :cpu=>nil, :start_time=>nil, :pid=>nil})
  end

  it "info_data + filter" do
    res = subject.info_data('app2')
    st = res[:subtree]
    st.size.should == 1
    p = st[0][:subtree][0][:subtree][0]
    p.should include(:name=>"z1", :state=>"unmonitored",
      :type=>:process, :resources=>{:memory=>nil, :cpu=>nil, :start_time=>nil, :pid=>nil})
  end

  it "short_data" do
    sleep 0.2
    res = subject.command(:short_data)
    res.should == {:subtree=>[{:name=>"app1", :type=>:application, :states=>{'unmonitored' => 5}},
      {:name=>"app2", :type=>:application, :states=>{"unmonitored" => 1}}]}
  end

  it "debug_data" do
    res = subject.command(:debug_data)
    res[:resources].should be_a(Hash)
    res[:config_yaml].should == nil

    res = subject.debug_data(:config => true)
    res[:resources].should be_a(Hash)
    res[:config_yaml].should be_a(String)
  end

  it "history_data" do
    h = subject.command(:history_data, 'app1')
    h.size.should == 5
    h.keys.sort.should == ["app1:g4", "app1:g5", "app1:gr1:p1", "app1:gr1:p2", "app1:gr2:q3"]
  end

end
