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
            raise Eye::Dsl::Error, "bad #{opt} value #{arg} type, should be #{types.inspect}" unless good_type
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

  def initialize(name = nil, parent = nil)
    @name = name.to_s    
    @full_name = @name

    if parent
      @parent = parent
      @config = Marshal.load(Marshal.dump(parent.config)) # O_o ruby recommended deep clone
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

  # execute part of config on particular server
  # array of strings
  # regexp
  # string
  def with_server(glob = nil, &block)
    on_server = true

    if glob.present? 
      host = Eye::System.host

      if glob.is_a?(Array)
        on_server = !!glob.any?{|elem| elem == host}
      elsif glob.is_a?(Regexp)
        on_server = !!host.match(glob)
      elsif glob.is_a?(String) || glob.is_a?(Symbol)
        on_server = (host == glob.to_s)
      end
    end

    with_condition(on_server, &block)

    on_server
  end

  def with_condition(cond = true, &block)
    self.instance_eval(&block) if cond && block
  end

  def include(proc, *args)
    ie = if proc.is_a?(Symbol) || proc.is_a?(String)
      if args.present?
        lambda{|i| i.send(proc, i, *args) }
      else
        method(proc).to_proc
      end
    else
      proc
    end

    self.instance_eval(&ie)
  end

end