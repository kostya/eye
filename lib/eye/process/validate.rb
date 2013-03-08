module Eye::Process::Validate

  class Error < Exception; end

  def validate(config)
    if config[:daemonize]
      if (str = config[:start_command])
        if str =~ %r[&&|;|sh \-c]
          raise Error, "#{config[:name]}, start_command in daemonize not supported shell concats like '&&'"
        end
      end
    end
  end

end