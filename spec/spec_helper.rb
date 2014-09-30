require 'rubygems'
require "bundler/setup"
Bundler.require :default

if ENV['COV']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/bundle/"
  end
end

if ENV['COVA']
  ENV["COVERALLS_SILENT"] = '1'
  require 'coveralls'
  Coveralls.wear_merged!
end

# preload
Eye::Controller
Eye::Process

class Eye::Controller
  public :find_objects, :remove_object_from_tree, :matched_objects
  def load_erb(file); with_erb_file(file){|f| self.load(f) }; end
  def load_content(cont); res = nil; with_temp_file(cont){|f| res = self.load(f) }; res; end
end

require 'rspec/mocks'
require 'fakeweb'
require 'ostruct'

require File.join(File.dirname(__FILE__), %w{support spec_support})
require File.join(File.dirname(__FILE__), %w{support load_result})

def process_id
  ENV['TEST_ENV_NUMBER'].to_i
end

ENV['EYE_FULL_BACKTRACE'] = '1'

$logger_path = File.join(File.dirname(__FILE__), ["spec#{process_id}.log"])

def set_glogger
  Eye::Logger.log_level = Logger::DEBUG
  Eye::Logger.link_logger($logger_path)
end

set_glogger

$logger = Eye::Logger.new("spec")
Celluloid.logger = $logger
STDERR.reopen($logger_path)

$logger.info "specs started in process #{$$}"

RSpec.configure do |config|
  if ENV['PROFILE']
    require 'parallel_tests/rspec/runtime_logger'
    config.formatters << ParallelTests::RSpec::RuntimeLogger.new("spec/weights.txt")
  end

  config.mock_with :rr

  config.before(:all) do
    Eye::SystemResources.cache.setup_expire(1.0)
  end

  config.before(:each) do
    SimpleCov.command_name "RSpec:#{Process.pid}#{ENV['TEST_ENV_NUMBER']}" if defined?(SimpleCov)

    clear_pids

    @log = C.base[:stdout]
    FileUtils.rm(@log) rescue nil
    @pids = []
    $unique_num = 0

    stub(Eye::Local).dir { C.sample_dir }

    $logger.info "================== #{ self.class.description} '#{ example.description }'========================"
  end

  config.after(:each) do
    force_kill_process(@process)
    force_kill_pid(@pid)

    if @pids && @pids.present?
      @pids.each { |p| force_kill_pid(p) }
    end

    terminate_old_actors

    # actors = Celluloid::Actor.all.map(&:class)
    # $logger.info "Actors: #{actors.inspect}"
  end

  config.after(:all) do
    FakeWeb.allow_net_connect = true
  end
end

def clear_pids
  (C.p.values).each do |cfg|
    FileUtils.rm(cfg[:pid_file]) rescue nil
  end
  FileUtils.rm(C.just_pid) rescue nil
  FileUtils.rm(C.tmp_file) rescue nil
end

def terminate_old_actors
  Celluloid::Actor.all.each do |actor|
    next unless actor.alive?
    if [Eye::Controller, Eye::Process, Eye::Group, Eye::ChildProcess].include?(actor.class)
      next if actor == Eye::Control
      actor.terminate
    end
  end

rescue => ex
  $logger.error [ex.message, ex.backtrace]
end

def force_kill_process(process)
  if process && process.alive?
    pid = process.pid rescue nil
    process.terminate rescue nil

    force_kill_pid(pid)
  end
end

def force_kill_pid(pid)
  if pid && pid != $$ && Eye::System.pid_alive?(pid)
    Eye::System.send_signal(pid, 9)
  end
end

def fixture(name)
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', name))
end

def join(*args)
  result = {}
  args.each do |a|
    result.merge!(a)
  end

  result
end

def should_spend(timeout = 0, delta = 0.05, &block)
  tm1 = Time.now
  yield
  (Time.now - tm1).should be_within(delta).of(timeout)
end

def with_erb_file(file, &block)
  require 'erb'
  filename = file + "#{rand.to_f}.eye"
  File.open(filename, 'w'){ |f| f.write ERB.new(File.read(file)).result }
  yield filename
ensure
  FileUtils.rm(filename) rescue nil
end

def with_temp_file(cont, &block)
  filename = C.sample_dir + "#{rand.to_f}.eye"
  $logger.info cont
  File.open(filename, 'w'){ |f| f.write cont }
  yield filename
ensure
  FileUtils.rm(filename) rescue nil
end

def start_controller
  @controller = Eye::Controller.new
  res = yield

  @processes = @controller.all_processes

  # wait for all processes to up
  @processes.pmap do |p|
    p.wait_for_condition(10, 0.3) do
      p.state_name == :up
    end
  end

  @pids = @processes.map(&:pid)

  @p1 = @processes.detect{|c| c.name == 'sample1' }
  @p2 = @processes.detect{|c| c.name == 'sample2' }
  @p3 = @processes.detect{|c| c.name == 'forking' }

  @old_pid1 = @p1.pid
  @old_pid2 = @p2.pid
  @old_pid3 = @p3.pid

  res
end

def stop_controller
  return unless @controller

  @processes.pmap { |p| p.stop if p.alive? }
  @processes.each { |p| force_kill_process(p) if p.alive? }

  # if processes was reloaded
  processes = @controller.all_processes
  processes.pmap { |p| p.stop if p.alive? }
  processes.each { |p| force_kill_process(p) if p.alive? }

  $logger.info "force_kill_pid: #{@pids}"
  @pids.each { |pid| force_kill_pid(pid) }
  @pids = []
end
