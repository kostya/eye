# mini bundler, for embedded server gem installation

gem 'celluloid',     '~> 0.14.0'
gem 'celluloid-io',  '~> 0.14.0'
gem 'nio4r'
gem 'timers'

gem 'state_machine'

if RUBY_VERSION == '1.9.2'
  gem 'activesupport', '>= 3', '< 4.0'
else
  gem 'activesupport', '>= 3'
end
