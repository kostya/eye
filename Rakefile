#!/usr/bin/env rake

require 'bundler/gem_tasks'
require 'coveralls/rake/task'

Coveralls::RakeTask.new

task default: :split_test

desc 'run parallel tests'
task :pspec do
  dirname = File.expand_path(File.dirname(__FILE__))
  cmd = "bundle exec parallel_rspec -n #{ENV['N'] || 10} --runtime-log '#{dirname}/spec/weights.txt' #{dirname}/spec"
  abort unless system(cmd)
end

desc 'run parallel split tests'
task :split_test do
  dirname = File.expand_path(File.dirname(__FILE__))
  ENV['PARALLEL_SPLIT_TEST_PROCESSES'] = (ENV['N'] || 10).to_s
  cmd = "bundle exec parallel_split_test #{dirname}/spec"
  abort unless system(cmd)
end

task :remove_coverage do
  require 'fileutils'
  FileUtils.rm_rf(File.expand_path(File.join(File.dirname(__FILE__), %w[coverage])))
end

task :env do
  require 'bundler/setup'
  require 'eye'
  Eye::Controller
  Eye::Process
end

desc 'graph'
task graph: :env do
  StateMachine::Machine.draw('Eye::Process')
end
