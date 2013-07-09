require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Process::Notify" do
  before :each do
    stub(Eye::System).host{ 'host1' }
    @process = process(C.p1.merge(:notify => {'vasya' => :info,
      'petya' => :warn, 'somebody' => :warn}))
  end

  it "should send to notifies warn message" do
    m = {:message=>"something", :name=>"blocking process", :full_name=>"main:default:blocking process", :pid=>nil, :host=>"host1", :level=>:info}
    mock(Eye::Notify).notify('vasya', hash_including(m))
    @process.notify(:info, 'something')
  end

  it "should send to notifies crit message" do
    m = {:message=>"something", :name=>"blocking process",
      :full_name=>"main:default:blocking process", :pid=>nil,
      :host=>'host1', :level=>:warn}

    mock(Eye::Notify).notify('vasya', hash_including(m))
    mock(Eye::Notify).notify('petya', hash_including(m))
    mock(Eye::Notify).notify('somebody', hash_including(m))
    @process.notify(:warn, 'something')
  end

end