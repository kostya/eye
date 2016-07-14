module Eye::Dsl::Validation

  def self.included(base)
    base.extend(ClassMethods)
  end

  class Error < RuntimeError; end

  module ClassMethods

    def inherited(subclass)
      subclass.validates = validates.clone
      subclass.should_bes = should_bes.clone
      subclass.defaults = defaults.clone
      subclass.variants = variants.clone
    end

    attr_accessor :validates, :should_bes, :defaults, :variants

    def validates
      @validates ||= {}
    end

    def should_bes
      @should_bes ||= []
    end

    def defaults
      @defaults ||= {}
    end

    def variants
      @variants ||= {}
    end

    def param(param, types = [], should_be = false, default = nil, variants = nil)
      param = param.to_sym

      validates[param] = types
      should_bes << param if should_be
      param_default(param, default)
      self.variants[param] = variants

      return if param == :do

      define_method param do
        value = @options[param]
        value.nil? ? self.class.defaults[param] : value
      end

      define_method "#{param}=" do |value|
        @options[param] = value
      end
    end

    def param_default(param, default)
      param = param.to_sym
      defaults[param] = default
    end

    def del_param(param)
      param = param.to_sym
      validates.delete(param)
      should_bes.delete(param)
      defaults.delete(param)
      variants.delete(param)
      remove_method(param)
    end

    def validate(options = {})
      options.each { |param, value| validate_param(param, value) }

      should_bes.each do |param|
        raise Error, "#{name} for param :#{param} value should be" unless options[param.to_sym] || defaults[param.to_sym]
      end
    end

    def validate_param(param, value)
      param = param.to_sym
      types = validates[param]
      if !types && param != :type
        raise Error, "#{name} unknown param :#{param} value #{value.inspect}"
      end

      if variants[param] && value && !value.is_a?(Proc)
        if value.is_a?(Array)
          value = value.reject { |v| v.is_a?(Proc) }
          if (value - variants[param]).present?
            raise Error, "#{value.inspect} should be within #{variants[param].inspect}"
          end
        elsif !variants[param].include?(value)
          raise Error, "#{value.inspect} should be within #{variants[param].inspect}"
        end
      end

      if types.present?
        types = Array(types)
        good = types.any? { |type| value.is_a?(type) }
        raise Error, "#{name} bad param :#{param} value #{value.inspect}, type #{types.inspect}" unless good
      end
    end

  end

end
