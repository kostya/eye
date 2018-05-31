Eye.application 'app1' do
  working_dir '/tmp'

  group 'gr1' do
    process('p1') { pid_file 'app1-gr1-p1.pid' }
  end
end
