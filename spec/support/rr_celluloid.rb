require 'rr'
require 'rspec/core/mocking/with_rr'

module RR

  module Celluloid
    def mock(subject=DoubleDefinitions::DoubleDefinitionCreate::NO_SUBJECT, method_name=nil, &definition_eval_block)
      s = subject.respond_to?(:wrapped_object) ? subject.wrapped_object : subject
      super(s, method_name, &definition_eval_block)
    end

    def stub(subject=DoubleDefinitions::DoubleDefinitionCreate::NO_SUBJECT, method_name=nil, &definition_eval_block)
      s = subject.respond_to?(:wrapped_object) ? subject.wrapped_object : subject
      super(s, method_name, &definition_eval_block)
    end
    
    def dont_allow(subject=DoubleDefinitions::DoubleDefinitionCreate::NO_SUBJECT, method_name=nil, &definition_eval_block)
      s = subject.respond_to?(:wrapped_object) ? subject.wrapped_object : subject
      super(s, method_name, &definition_eval_block)
    end
    
    def proxy(subject=DoubleDefinitions::DoubleDefinitionCreate::NO_SUBJECT, method_name=nil, &definition_eval_block)
      s = subject.respond_to?(:wrapped_object) ? subject.wrapped_object : subject
      super(s, method_name, &definition_eval_block)
    end
    
    def strong(subject=DoubleDefinitions::DoubleDefinitionCreate::NO_SUBJECT, method_name=nil, &definition_eval_block)
      s = subject.respond_to?(:wrapped_object) ? subject.wrapped_object : subject
      super(s, method_name, &definition_eval_block)
    end

  end
  
end

RSpec::Core::MockFrameworkAdapter.send(:include, RR::Celluloid)
