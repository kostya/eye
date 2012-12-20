require File.dirname(__FILE__) + '/../spec_helper'

def app_check(app, name, gr_size)
  app.name.should == name
  app.class.should == Eye::Application
  app.groups.size.should == gr_size
end

def gr_check(gr, name, p_size, hidden = false)
  gr.class.should == Eye::Group
  gr.processes.size.should == p_size
  gr.name.should == name
  gr.hidden.should == hidden
end

def p_check(p, name, pid_file)
  p.name.should == name
  p.class.should == Eye::Process
  p[:pid_file].should == "#{pid_file}"
  p[:pid_file_ex].should == "/tmp/#{pid_file}"
end

describe "Eye::Controller" do
  subject{ controller_new }

  it "should ok load config" do
    subject.load(fixture("dsl/load.eye")).should == {:error => false}

    apps = subject.applications

    app1 = apps.first
    app_check(app1, 'app1', 3)
    app2 = apps.last
    app_check(app2, 'app2', 1)

    gr1 = app1.groups[0]
    gr_check(gr1, 'gr1', 2, false)
    gr2 = app1.groups[1]
    gr_check(gr2, 'gr2', 1, false)
    gr3 = app1.groups[2]
    gr_check(gr3, '__default__', 2, true)
    gr4 = app2.groups[0]
    gr_check(gr4, '__default__', 1, true)

    p1 = gr1.processes[0]
    p_check(p1, 'p1', "app1-gr1-p1.pid")
    p2 = gr1.processes[1]
    p_check(p2, 'p2', "app1-gr1-p2.pid")

    p3 = gr2.processes[0]
    p_check(p3, 'q3', "app1-gr2-q3.pid")

    p4 = gr3.processes[0]
    p_check(p4, 'g4', "app1-g4.pid")
    p5 = gr3.processes[1]
    p_check(p5, 'g5', "app1-g5.pid")

    p6 = gr4.processes[0]
    p_check(p6, 'z1', "app2-z1.pid")
  end

  it "raise when load config" do
    subject.load(fixture("dsl/bad.eye")).should include(:error => true, :message => "blank pid_file for: bad")
  end

  it "status_string" do
    str = <<S
[app1]                                
  [gr1]                               
    p1 .......................        : unmonitored
    p2 .......................        : unmonitored
  [gr2]                               
    q3 .......................        : unmonitored
  g4 .........................        : unmonitored
  g5 .........................        : unmonitored
[app2]                                
  z1 .........................        : unmonitored
S

    subject.load(fixture("dsl/load.eye"))
    subject.status_string.should == str.chomp
  end

  describe "command" do
    it "should send_command" do
      mock(Eye.controller).send_command(:restart, 'samples')
      Eye.controller.command('restart', 'samples')
    end

    it "should send_command" do
      mock(Eye.controller).send_command(:restart)
      Eye.controller.command(:restart)
    end

    it "load" do
      mock(Eye.controller).load('/tmp/file')
      Eye.controller.command('load', '/tmp/file')
    end

    it "status" do
      mock(Eye.controller).status_string
      Eye.controller.command('status')
    end

    it "quit" do
      mock(Eye.controller).quit
      Eye.controller.command('quit')
    end

  end

end