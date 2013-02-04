module Eye::Checker::Validation
  class Error < Exception; end

  def inherited(subclass)
    subclass.validates = self.validates.clone
    subclass.should_bes = self.should_bes.clone
    subclass.defaults = self.defaults.clone
  end

  attr_accessor :validates, :should_bes, :defaults

  def validates; @validates ||= {}; end
  def should_bes; @should_bes ||= []; end
  def defaults; @defaults ||= {}; end

  def param(param, types = [], should_be = false, default = nil)
    param = param.to_sym

    validates[param] = types
    should_bes << param if should_be
    defaults[param] = default

    define_method "#{param}" do
      @options[param.to_sym] || default
    end
  end

  def validate(options = {})    
    options.each do |param, value|        
      types = validates[param.to_sym]
      unless types
        if param.to_sym != :type
          raise Error, "#{self.name} unknown param :#{param} value #{value.inspect}" 
        end
      end

      next if types.blank?

      types = Array(types)
      good = types.any?{|type| value.is_a?(type) }
      raise Error, "#{self.name} bad param :#{param} value #{value.inspect}, type #{types.inspect}" unless good
    end

    should_bes.each do |param|
      raise Error, "#{self.name} bad param :#{param}, value should be" unless options[param.to_sym] || defaults[param.to_sym]
    end
  end

end