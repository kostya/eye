Eye.application 'app4' do
  working_dir '/tmp'

  process 'e1' do
    pid_file 'app3-e1.pid'
  end
end
