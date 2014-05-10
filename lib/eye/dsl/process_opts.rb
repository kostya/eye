class Eye::Dsl::ProcessOpts < Eye::Dsl::Opts

  def monitor_children(&block)
    opts = Eye::Dsl::ChildProcessOpts.new
    opts.instance_eval(&block) if block
    @config[:monitor_children] ||= {}
    @config[:monitor_children].merge!(opts.config)
  end

  alias xmonitor_children nop

  def application
    parent.try(:parent)
  end
  alias app application
  alias group parent

  def depends_on(names, opts = {})
    names = Array(names)
    trigger(:wait_dependency, :names => names)
    names.each do |name|
      parent.process name do
        trigger(:check_dependency, { :names => %w{self[:name]} }.merge(opts) )
      end
    end
  end

end