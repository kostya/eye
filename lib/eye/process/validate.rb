require 'shellwords'
require 'etc'

module Eye::Process::Validate

  class Error < Exception; end

  def validate(config)
    if (str = config[:start_command])
      # it should parse with Shellwords and not raise
      spl = Shellwords.shellwords(str) * '#'

      if config[:daemonize]
        if spl =~ %r[sh#\-c|#&&#|;#]
          raise Error, "#{config[:name]}, start_command in daemonize not supported shell concats like '&&'"
        end
      end
    end

    Shellwords.shellwords(config[:stop_command]) if config[:stop_command]
    Shellwords.shellwords(config[:restart_command]) if config[:restart_command]

    Etc.getpwnam(config[:uid]) if config[:uid]
    Etc.getpwnam(config[:gid]) if config[:gid]

    if config[:working_dir]
      raise Error, "working_dir '#{config[:working_dir]}' is invalid" unless File.directory?(config[:working_dir])
    end
  end

end
