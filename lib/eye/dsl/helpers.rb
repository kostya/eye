
# Dsl Helpers

# current eye parsed config path
def current_config_path
  Eye.parsed_filename && File.symlink?(Eye.parsed_filename) ? File.readlink(Eye.parsed_filename) : Eye.parsed_filename
end

# host name
def hostname
  Eye::Local.host
end

def example_process(proxy, name)
  proxy.process(name) do
    pid_file "/tmp/#{name}.pid"
    start_command "sleep 100"
    daemonize true
  end
end
