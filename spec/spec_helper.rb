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
  require 'coveralls'
  Coveralls.wear!
end

# preload
Eye::Control
Eye::Controller
Eye::Process

class Eye::Controller
  public :find_objects, :remove_object_from_tree
end

require 'rspec/mocks'
require 'fakeweb'

require File.join(File.dirname(__FILE__), %w{support spec_support})
require File.join(File.dirname(__FILE__), %w{support load_result})

def process_id
  ENV['TEST_ENV_NUMBER'].to_i
end

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
  config.mock_with :rr

  config.before(:all) do
    silence_warnings{ Eye::SystemResources::PsAxActor::UPDATE_INTERVAL = 2 }
  end

  config.before(:each) do
    clear_pids

    @log = C.base[:stdout]
    FileUtils.rm(@log) rescue nil

    stub(Eye::Settings).dir { C.sample_dir }

    $logger.info "================== #{ self.class.description} '#{ example.description }'========================"
  end

  config.after(:each) do
    force_kill_process(@process)
    force_kill_pid(@pid)

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
end

def terminate_old_actors
  Celluloid::Actor.all.each do |actor|
    next unless actor.alive?
    if [Eye::Controller, Eye::Process, Eye::Group, Eye::ChildProcess].include?(actor.class)
      next if actor == Eye::Control
      actor.terminate
    end
  end
rescue
end

def force_kill_process(process)
  if process && process.alive?
    pid = process.pid

    process.terminate
    force_kill_pid(pid)

    process = nil
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

