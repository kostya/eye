#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rspec/core/rake_task'
task :default => :spec
RSpec::Core::RakeTask.new(:spec)

task :env do
  require 'bundler/setup'
  require 'eye'
  Eye::Process # preload
end

desc "graph"
task :graph => :env do
  StateMachine::Machine.draw("Eye::Process")
end
