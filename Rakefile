#!/usr/bin/env rake

require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'parallel_tests/tasks'
require 'coveralls/rake/task'

Coveralls::RakeTask.new

task :default => :pspecs

task :pspecs do
  Rake::Task['parallel:spec'].invoke(ENV['N'] || 8)
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

task :remove_coverage do
  require 'fileutils'
  FileUtils.rm_rf(File.expand_path(File.join(File.dirname(__FILE__), %w{ coverage })))
end

task :env do
  require 'bundler/setup'
  require 'eye'
  Eye::Controller
  Eye::Process # preload
end

desc "graph"
task :graph => :env do
  StateMachine::Machine.draw("Eye::Process")
end
