require 'celluloid'

class Eye::Utils::CelluloidChain

  include Celluloid

  def initialize(target)
    @target = target
    @calls = []
    @running = false
    @target_class = @target.class
  end

  def add(method_name, *args)
    @calls << { method_name: method_name, args: args }
    ensure_process
  end

  def add_wo_dups(method_name, *args)
    h = { method_name: method_name, args: args }
    if @calls[-1] != h
      @calls << h
      ensure_process
    end
  end

  def add_wo_dups_current(method_name, *args)
    h = { method_name: method_name, args: args }
    if !@calls.include?(h) && @call != h
      @calls << h
      ensure_process
    end
  end

  def list
    @calls
  end

  def names_list
    list.map { |el| el[:method_name].to_sym }
  end

  def clear
    @calls = []
  end

  alias_method :clear_pending_list, :clear

  # need, because of https://github.com/celluloid/celluloid/issues/22
  def inspect
    "Celluloid::Chain(#{@target_class}: #{@calls.size})"
  end

  attr_reader :running

private

  def ensure_process
    unless @running
      @running = true
      async.process
    end
  end

  def process
    while @call = @calls.shift
      @running = true
      @target.send(@call[:method_name], *@call[:args]) if @target.alive?
    end
    @running = false
  end

end
