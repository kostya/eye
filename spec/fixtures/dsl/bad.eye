Eye.application 'bla' do
  process 'bad' do
    # bad because not pid_file
    working_dir '/tmp'
  end
end
