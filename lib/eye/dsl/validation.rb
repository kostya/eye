module Eye::Dsl::Validation
  def self.included(base)
    base.extend(ClassMethods)
  end

  class Error < Exception; end

  module ClassMethods
    def inherited(subclass)
      subclass.validates = self.validates.clone
      subclass.should_bes = self.should_bes.clone
      subclass.defaults = self.defaults.clone
      subclass.variants = self.variants.clone
    end

    attr_accessor :validates, :should_bes, :defaults, :variants

    def validates; @validates ||= {}; end
    def should_bes; @should_bes ||= []; end
    def defaults; @defaults ||= {}; end
    def variants; @variants ||= {}; end

    def param(param, types = [], should_be = false, default = nil, _variants = nil)
      param = param.to_sym

      validates[param] = types
      should_bes << param if should_be
      param_default(param, default)
      variants[param] = _variants

      return if param == :do

      define_method "#{param}" do
        value = @options[param]
        value.nil? ? default : value
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
      options.each do |param, value|
        param = param.to_sym
        types = validates[param]
        unless types
          if param != :type
            raise Error, "#{self.name} unknown param :#{param} value #{value.inspect}"
          end
        end

        if self.variants[param]
          if value && !value.is_a?(Proc)
            if value.is_a?(Array)
              if (value - self.variants[param]).present?
                raise Error, "#{value.inspect} should be within #{self.variants[param].inspect}"
              end
            elsif !self.variants[param].include?(value)
              raise Error, "#{value.inspect} should be within #{self.variants[param].inspect}"
            end
          end
        end

        next if types.blank?

        types = Array(types)
        good = types.any?{|type| value.is_a?(type) }
        raise Error, "#{self.name} bad param :#{param} value #{value.inspect}, type #{types.inspect}" unless good
      end

      should_bes.each do |param|
        raise Error, "#{self.name} for param :#{param} value should be" unless options[param.to_sym] || defaults[param.to_sym]
      end
    end
  end

end