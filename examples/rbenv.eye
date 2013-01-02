Eye.application "rbenv_example" do
  env 'RBENV_ROOT' => '/usr/local/rbenv', 'PATH' => "/usr/local/rbenv/shims:/usr/local/rbenv/bin:#{ENV['PATH']}"
  working_dir "/projects/some_project"
  
  process "some_process" do
    pid_file "some.pid"
    start_command "ruby some.rb"
    daemonize true
    stdall "some.log"
  end
end