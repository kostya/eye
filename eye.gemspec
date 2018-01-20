require File.expand_path('../lib/eye', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = 'Konstantin Makarchev'
  gem.email         = 'eye-rb@googlegroups.com'

  gem.description   = gem.summary = \
    'Process monitoring tool. Inspired from Bluepill and God. Requires Ruby(MRI) >= 1.9.3-p194. Uses Celluloid and Celluloid::IO.'
  gem.homepage      = 'http://github.com/kostya/eye'

  gem.files         = `git ls-files`.split($\).reject { |n| n =~ %r[png|gif\z] }.reject { |n| n =~ %r[^(test|spec|features)/] }
  gem.executables   = gem.files.grep(%r[^bin/]).map { |f| File.basename(f) }
  # gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'eye'
  gem.require_paths = ['lib']
  gem.version       = Eye::VERSION
  gem.license       = 'MIT'

  gem.required_ruby_version     = '>= 1.9.2'
  gem.required_rubygems_version = '>= 1.3.6'

  gem.add_dependency 'celluloid',     '~> 0.17.3'
  gem.add_dependency 'celluloid-io',  '~> 0.17.0'
  gem.add_dependency 'state_machines'
  gem.add_dependency 'thor'
  gem.add_dependency 'kostya-sigar', '~> 2.0.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '< 2.14'
  gem.add_development_dependency 'rr', '1.1.2'
  gem.add_development_dependency 'ruby-graphviz'
  gem.add_development_dependency 'forking'
  gem.add_development_dependency 'fakeweb'
  gem.add_development_dependency 'eventmachine', '>= 1.0.3'
  gem.add_development_dependency 'sinatra'
  gem.add_development_dependency 'thin'
  gem.add_development_dependency 'xmpp4r'
  gem.add_development_dependency 'slack-notifier'
  gem.add_development_dependency 'coveralls'
  gem.add_development_dependency 'tins', '1.6.0' # for coveralls
  gem.add_development_dependency 'simplecov', '>= 0.8.1'
  gem.add_development_dependency 'parallel_tests', '<= 1.3.1'
  gem.add_development_dependency 'parallel_split_test'
  gem.add_development_dependency 'rubocop'
end
