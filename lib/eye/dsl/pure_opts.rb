class Eye::Dsl::PureOpts

  def self.create_options_methods(arr, types = nil)
    m = Module.new do
      arr.each do |opt|
        define_method("set_#{opt}") do |arg|
          key = opt.to_sym

          if (disallow_options && disallow_options.include?(key)) || (allow_options && !allow_options.include?(key))
            raise Eye::Dsl::Error, "disallow option #{key} for #{self.class.inspect}"
          end

          if types
            good_type = Array(types).any?{|type| arg.is_a?(type) } || arg.nil?
            raise Eye::Dsl::Error, "bad :#{opt} value #{arg.inspect}, type should be #{types.inspect}" unless good_type
          end

          @config[key] = arg
        end

        define_method("get_#{opt}") do
          @config[ opt.to_sym ]
        end

        define_method(opt) do |*args|
          if args.blank?
            # getter
            send "get_#{opt}"
          else
            send "set_#{opt}", *args
          end
        end

        define_method("#{opt}=") do |arg|
          send opt, arg
        end
      end
    end

    self.send :include, m
  end

  attr_reader :name, :full_name
  attr_reader :config, :parent

  def initialize(name = nil, parent = nil, merge_parent_config = true)
    @name = name.to_s
    @full_name = @name

    if parent
      @parent = parent
      if merge_parent_config
        @config = Eye::Utils::deep_clone(parent.config)
        parent.not_seed_options.each { |opt| @config.delete(opt) }
      else
        @config = {}
      end
      @full_name = "#{parent.full_name}:#{@full_name}"
    else
      @config = {}
    end

    @config[:name] = @name if @name.present?
  end

  def allow_options
    nil
  end

  def disallow_options
    []
  end

  def not_seed_options
    []
  end

  def with_condition(cond = true, &block)
    self.instance_eval(&block) if cond && block
  end

  def use(proc, *args)
    if proc.is_a?(String)
      self.class.with_parsed_file(proc) do |path|
        if File.exists?(path)
          Eye::Dsl.debug { "=> load #{path}" }
          self.instance_eval(File.read(path))
          Eye::Dsl.debug { "<= load #{path}" }
        end
      end
    else
      ie = if args.present?
        lambda{|i| proc[i, *args] }
      else
        proc
      end

      self.instance_eval(&ie)
    end
  end

  def nop(*args, &block); end

private

  def self.with_parsed_file(file_name)
    saved_parsed_filename = Eye.parsed_filename


    real_filename = Eye.parsed_filename && File.symlink?(Eye.parsed_filename) ? File.readlink(Eye.parsed_filename) : Eye.parsed_filename
    dirname = File.dirname(real_filename) rescue nil
    path = File.expand_path(file_name, dirname)

    Eye.parsed_filename = path
    yield path
  ensure
    Eye.parsed_filename = saved_parsed_filename
  end

end
