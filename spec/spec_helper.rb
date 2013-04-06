require 'rubygems'
require "bundler/setup"
require 'celluloid'

if ENV['COV']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/bundle/"
  end
end

Bundler.require :default

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
require File.join(File.dirname(__FILE__), %w{support scheduler_hack})

$logger_path = File.join(File.dirname(__FILE__), %w{spec.log})

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
    FileUtils.rm(C.p1[:pid_file]) rescue nil
    FileUtils.rm(C.p2[:pid_file]) rescue nil

    @log = C.base[:stdout]
    FileUtils.rm(@log) rescue nil

    $logger.info "================== #{ self.class.description} '#{ example.description }'========================"
  end

  config.after(:each) do
    # clearing all

    if @pid_file
      FileUtils.rm(@pid_file) rescue nil
    end

    force_kill_process(@process)
    force_kill_pid(@pid)

    FileUtils.rm(C.p1[:pid_file]) rescue nil
    FileUtils.rm(C.p2[:pid_file]) rescue nil

    GC.start # for kill spawned threads

    terminate_old_actors

    # actors = Celluloid::Actor.all.map(&:class)
    # $logger.info "Actors: #{actors.inspect}"
  end
end

def terminate_old_actors
  Celluloid::Actor.all.each do |actor|
    next unless actor.alive?
    if [Eye::Process, Eye::Group, Eye::ChildProcess].include?(actor.class)
      actor.terminate 
    end
  end
end

def force_kill_process(process)
  if process && process.alive?
    pid = process.pid

    process.terminate

    if pid && Eye::System.pid_alive?(pid)
      Eye::System.send_signal(pid, 9) 
    end

    process = nil
  end
end

def force_kill_pid(pid)
  if pid && Eye::System.pid_alive?(pid)
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
