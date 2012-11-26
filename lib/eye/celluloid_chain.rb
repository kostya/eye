class Celluloid::Chain
  include Celluloid

  def initialize(target)
    @target = target
    @calls = []
    @running = false
  end

  def add(method_name, *args, &block)
    @calls << {:method_name => method_name, :args => args, :block => block}
    process! unless @running
  end

  def add_no_dup(method_name, *args, &block)
    h = {:method_name => method_name, :args => args, :block => block}
    @calls << h if @calls[-1] != h
    process! unless @running
  end

  def list
    @calls
  end

  def clear
    @calls = []
  end

  # need, because of https://github.com/celluloid/celluloid/issues/22
  def inspect
    "Celluloid::Chain(#{@target.class}: #{@calls.inspect})"
  end

  attr_reader :running

private

  def process
    while call = @calls.shift
      @running = true
      @target.send(call[:method_name], *call[:args], &call[:block]) if @target.alive?
    end
    @running = false
  end
end