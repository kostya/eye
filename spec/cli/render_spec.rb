require File.dirname(__FILE__) + '/../spec_helper'

class String
  def clean_info
    self.gsub(%r{\033.*?m}im, '').gsub(%r[\(.*?\)], '').gsub(%r|(\s+)$|, '')
  end
end

describe "Eye::Cli" do
  let(:controller) { Eye::Controller.new }
  let(:cli) { Eye::Cli.new }

  def info_string(*args)
    cli.send(:render_info, controller.info_data(*args)).clean_info
  end

  def short_string(*args)
    cli.send(:render_info, controller.short_data(*args)).clean_info
  end

  def debug_string(*args)
    cli.send(:render_debug_info, controller.debug_data(*args)).clean_info
  end

  def history_string(*args)
    cli.send(:render_history, controller.history_data(*args)).clean_info
  end

  it "render_info" do
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

    controller.load(fixture("dsl/load.eye"))
    sleep 0.5
    info_string.strip.should == (app1 + app2).strip
    info_string('app1').should == app1.chomp
    info_string('app2').strip.should == app2.strip
    info_string('app3', :some_arg => :ignored).should == ''

    # wrong arg should not crash
    info_string(['1']).should == ''
  end

  it "render_info with reason" do
    controller.load(fixture("dsl/load.eye"))
    controller.command(:start)
    controller.command(:stop)
    sleep 0.5
    info_string.should be
  end

  it "info_string_debug should be" do
    controller.load(fixture("dsl/load.eye"))
    debug_string.split("\n").size.should > 5

    controller.load(fixture("dsl/load.eye"))
    debug_string(:config => true, :processes => true).split("\n").size.should > 5
  end

  it "info_string_short should be" do
    controller.load(fixture("dsl/load.eye"))
    short_string.should == "app1 ............... unmonitored:5\napp2 ............... unmonitored:1"
  end

  it "history_string" do
    controller.load(fixture("dsl/load.eye"))
    str = history_string('*')
    str.should be_a(String)
    str.size.should > 100
  end

end
