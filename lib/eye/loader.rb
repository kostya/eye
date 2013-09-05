# add gems to $: by `gem` method
#  this is only way when install eye as system wide

gem 'celluloid',     '~> 0.15.0'
gem 'celluloid-io',  '~> 0.15.0'
gem 'nio4r'
gem 'timers'

gem 'state_machine'
gem 'sigar'

if RUBY_VERSION == '1.9.2'
  gem 'activesupport', '>= 3', '< 4.0'
else
  gem 'activesupport', '>= 3'
end
