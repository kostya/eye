module Eye::Dsl::Validation
  class Error < Exception; end

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
    defaults[param] = default
    variants[param] = _variants

    define_method "#{param}" do
      @options[param.to_sym] || default
    end
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
        if value && !value.is_a?(Proc) && !self.variants[param].include?(value)
          raise Error, "#{value.inspect} should within #{self.variants[param].inspect}" 
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