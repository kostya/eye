require File.dirname(__FILE__) + '/../spec_helper'

class String
  def clean_info
    self.gsub(%r{\033.*?m}im, '').gsub(%r[\(.*?\)], '').gsub(%r|(\s+)$|, '')
  end
end

def app_check(app, name, gr_size)
  app.name.should == name
  app.class.should == Eye::Application
  app.groups.size.should == gr_size
  app.groups.class.should == Eye::Utils::AliveArray
end

def gr_check(gr, name, p_size, hidden = false)
  gr.class.should == Eye::Group
  gr.processes.class.should == Eye::Utils::AliveArray
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
  subject{ Eye::Controller.new }

  it "should ok load config" do
    subject.load(fixture("dsl/load.eye")).should_be_ok

    apps = subject.applications

    app1 = apps.first
    app_check(app1, 'app1', 3)
    app1.processes.map(&:name).sort.should == ["g4", "g5", "p1", "p2", "q3"]

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
    subject.load(fixture("dsl/bad.eye")).only_value.should include(:error => true, :message => "blank pid_file for: bad")
  end

  it "info_string" do
    app1 = <<S
app1
  gr1
    p1 ............................ unmonitored
    p2 ............................ unmonitored
  gr2
    q3 ............................ unmonitored
  g4 .............................. unmonitored
  g5 .............................. unmonitored
S
    app2 = <<S
app2
  z1 .............................. unmonitored
S

    subject.load(fixture("dsl/load.eye"))
    sleep 0.5
    subject.info_string.clean_info.strip.should == (app1 + app2).strip
    subject.info_string('app1').clean_info.should == app1.chomp
    subject.info_string('app2').clean_info.strip.should == app2.strip
    subject.info_string('app3').clean_info.should == ''
  end

  it "info_string_debug should be" do
    subject.load(fixture("dsl/load.eye"))
    subject.info_string_debug.split("\n").size.should > 5

    subject.load(fixture("dsl/load.eye"))
    subject.info_string_debug(:config => true, :processes => true).split("\n").size.should > 5

    subject.__klass__.should == "Eye::Controller"
  end

  it "info_string_short should be" do
    subject.load(fixture("dsl/load.eye"))
    subject.info_string_short.split("\n").size.should == 2
  end

  it "history_string" do
    subject.load(fixture("dsl/load.eye"))
    str = subject.history_string('*')
    str.should be_a(String)
    str.size.should > 100
  end

  it "history_data" do
    subject.load(fixture("dsl/load.eye"))
    h = subject.history_data('app1')
    h.size.should == 5
    h.keys.sort.should == ["app1:g4", "app1:g5", "app1:gr1:p1", "app1:gr1:p2", "app1:gr2:q3"]
  end

  it "should save cache file" do
    FileUtils.rm(Eye::Settings.cache_path) rescue nil
    subject.load(fixture("dsl/load.eye"))
    File.exists?(Eye::Settings.cache_path).should be_true
  end

  it "should delete all apps" do
    subject.load(fixture("dsl/load.eye")).should_be_ok
    subject.send_command(:delete, 'all')
    subject.applications.should be_empty
  end

  describe "command" do
    it "should send_command" do
      mock(subject).send_command(:restart, 'samples')
      subject.command('restart', 'samples')
    end

    it "should send_command" do
      mock(subject).send_command(:restart)
      subject.command(:restart)
    end

    it "load" do
      mock(subject).load('/tmp/file')
      subject.command('load', '/tmp/file')
    end

    it "info" do
      mock(subject).info_string
      subject.command('info')
    end

    it "quit" do
      mock(subject).quit
      subject.command('quit')
    end

  end

end
