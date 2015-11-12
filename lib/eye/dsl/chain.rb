module Eye::Dsl::Chain

  def chain(opts = {})
    acts = Array(opts[:action] || opts[:actions] || [:start, :restart])

    acts.each do |act|
      @config[:chain] ||= {}
      @config[:chain][act] = opts.merge(action: act)
    end
  end

end
