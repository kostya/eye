require 'bundler/setup'
require 'sinatra'

class Test < Sinatra::Base

  get '/hello' do
    sleep 0.5
    'Hello World!'
  end

end

run Test.new
