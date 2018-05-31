Eye.application 'app4' do
  working_dir '/tmp'

  process 'e2' do
    pid_file 'app4-e2.pid'
  end
end
