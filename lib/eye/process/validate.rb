require 'shellwords'
require 'etc'

module Eye::Process::Validate

  class Error < Exception; end

  def validate(config, localize = true)
    if (str = config[:start_command])
      # it should parse with Shellwords and not raise
      spl = Shellwords.shellwords(str) * '#'

      if config[:daemonize] && !config[:use_leaf_child]
        if spl =~ %r[sh#\-c|#&&#|;#]
          raise Error, "#{config[:name]}, daemonize does not support concats like '&&' in start_command"
        end
      end
    end

    Shellwords.shellwords(config[:stop_command]) if config[:stop_command]
    Shellwords.shellwords(config[:restart_command]) if config[:restart_command]

    if localize
      Etc.getpwnam(config[:uid]) if config[:uid]
      Etc.getgrnam(config[:gid]) if config[:gid]

      if config[:working_dir]
        raise Error, "working_dir '#{config[:working_dir]}' is invalid" unless File.directory?(config[:working_dir])
      end
    end

    if config[:stop_signals]
      s = config[:stop_signals].clone
      while s.present?
        sig = s.shift
        timeout = s.shift
        raise Error, "signal should be String, Symbol, Fixnum, not #{sig.inspect}" if sig && ![String, Symbol, Fixnum].include?(sig.class)
        raise Error, "signal sleep should be Numeric, not #{timeout.inspect}" if timeout && ![Fixnum, Float].include?(timeout.class)
      end
    end
  end

end
