require 'rr'
require 'rspec/core/mocking/with_rr'

module RR::CelluloidExt
  %w{mock stub dont_allow proxy strong}.each do |_method|
    module_eval <<-Q
      def #{_method}(*args)
        args[0] = args[0].wrapped_object if args[0].respond_to?(:wrapped_object)
        super
      end
    Q
  end
end

RSpec::Core::MockFrameworkAdapter.send(:include, RR::CelluloidExt)
