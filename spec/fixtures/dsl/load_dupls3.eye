Eye.application 'someapp' do
end

Eye.application 'app' do
  process('someprocess') { pid_file 'someprocess.pid' }
end

Eye.application 'app2' do
  process('app') { pid_file 'app.pid' }
end
