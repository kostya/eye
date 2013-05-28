require 'bundler/setup'
require 'sinatra'

class Test < Sinatra::Base

  get '/hello' do
    sleep 0.5
    "Hello World!"
  end

  get '/timeout' do
    sleep 5
    "hehe"
  end
end

run Test.new
