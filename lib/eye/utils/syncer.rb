require 'celluloid'

# Celluloid hack
# TODO: remove for celluloid > 0.17?
class Celluloid::Future::Result

  def value
    @result.respond_to?(:value) ? @result.value : @result
  end

end

class Eye::Utils::Syncer

  DEFAULT_TIMEOUT = 300 # 5.minutes

  def initialize(timeout = nil, fake = false)
    @timeout = (timeout || DEFAULT_TIMEOUT).to_f
    @future = Celluloid::Future.new
    @fake = fake
  end

  def self.with(timeout = nil, &block)
    new(timeout).tap { |s| block.call(s) }.wait
  end

  def self.cast(syncer = nil)
    syncer || new(nil, true)
  end

  def done!
    return if @fake

    @future.signal(nil)
  end

  def wait(timeout = nil)
    return :ok if @fake

    @future.value(timeout || @timeout)
    :ok
  rescue Celluloid::TimedOut
    :timeouted
  end

  def group
    Group.new(@timeout, @fake)
  end

  def wait_group(signalling = true, &block)
    g = group
    block.call(g)
    res = g.wait
    done! if signalling
    @timeout = g.timeout
    res
  end

  class Group

    attr_reader :timeout

    def initialize(timeout = nil, fake = false)
      @timeout = (timeout || DEFAULT_TIMEOUT).to_f
      @group = []
      @fake = fake
    end

    def child
      Eye::Utils::Syncer.new(@timeout, @fake).tap { |s| @group << s }
    end

    def wait
      return :ok if @fake

      @group.each do |s|
        t = Time.now
        res = s.wait(@timeout)
        dt = Time.now - t
        @timeout -= dt
        @timeout = 0 if @timeout < 0
        return :timeouted if res == :timeouted
      end
      :ok
    end

  end

end
