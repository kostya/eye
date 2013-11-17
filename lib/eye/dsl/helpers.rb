
# Dsl Helpers

# current eye parsed config path
def current_config_path
  Eye.parsed_filename && File.symlink?(Eye.parsed_filename) ? File.readlink(Eye.parsed_filename) : Eye.parsed_filename
end

# host name
def hostname
  Eye::Local.host
end