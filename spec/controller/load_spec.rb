require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Controller::Load" do
  subject{ Eye::Controller.new($logger) }

  it "blank" do
    subject.load.should == {:error => false, :empty => true}
  end

  it "not exists file" do
    subject.load("/asdf/asd/fasd/fas/df/sfd").should == {:error => true, :message => "config file '/asdf/asd/fasd/fas/df/sfd' not found!"}
  end

  it "load + 1new app" do
    subject.load(fixture("dsl/load.eye")).should == {:error => false}
    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}

    subject.load(fixture("dsl/load2.eye")).should == {:error => false}

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}, 
      "app3"=>{"__default__"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "load 1 changed app" do
    subject.load(fixture("dsl/load.eye")).should == {:error => false}
    subject.load(fixture("dsl/load2.eye")).should == {:error => false}

    p = subject.process_by_name('e1')
    p[:daemonize].should == false

    dont_allow(p).queue

    subject.load(fixture("dsl/load3.eye")).should == {:error => false}

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}, 
      "app3"=>{"wow"=>{"e1"=>"/tmp/app3-e1.pid"}}}

    p2 = subject.process_by_name('e1')
    p2[:daemonize].should == true

    p.object_id.should == p2.object_id
  end

  it "load -> remove -> load" do
    subject.load(fixture("dsl/load.eye")).should == {:error => false}
    subject.load(fixture("dsl/load2.eye")).should == {:error => false}
    subject.command(:remove, 'app3')
    subject.load(fixture("dsl/load3.eye")).should == {:error => false}

    subject.short_tree.should == {
      "app1"=>{
        "gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr2"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}}, 
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}, 
      "app3"=>{"wow"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "load + 1 app, and pid_file crossed" do
    subject.load(fixture("dsl/load2.eye")).should == {:error => false}
    subject.load(fixture("dsl/load4.eye")).should include(:error => true, :message => 'dublicate pid_files: {"app3-e1.pid"=>2}')

    subject.short_tree.should == {
      "app3"=>{"__default__"=>{"e1"=>"/tmp/app3-e1.pid"}}}
  end

  it "process and groups disappears" do
    subject.load(fixture("dsl/load.eye")).should == {:error => false}
    subject.load(fixture("dsl/load5.eye")).should == {:error => false}

    group_actors = Celluloid::Actor.all.select{|c| c.class == Eye::Group }
    process_actors = Celluloid::Actor.all.select{|c| c.class == Eye::Process }

    subject.short_tree.should == {
      "app1"=>{"gr1"=>{"p1"=>"/tmp/app1-gr1-p1.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}

    group_actors.map{|a| a.name}.sort.should == %w{__default__ gr1}
    process_actors.map{|a| a.name}.sort.should == %w{p1 z1}
  end

  it "swap groups" do
    subject.load(fixture("dsl/load.eye")).should == {:error => false}
    subject.load(fixture("dsl/load6.eye")).should == {:error => false}

    subject.short_tree.should == {
      "app1" => {
        "gr2"=>{"p1"=>"/tmp/app1-gr1-p1.pid", "p2"=>"/tmp/app1-gr1-p2.pid"}, 
        "gr1"=>{"q3"=>"/tmp/app1-gr2-q3.pid"}, 
        "__default__"=>{"g4"=>"/tmp/app1-g4.pid", "g5"=>"/tmp/app1-g5.pid"}},
      "app2"=>{"__default__"=>{"z1"=>"/tmp/app2-z1.pid"}}}
  end

end