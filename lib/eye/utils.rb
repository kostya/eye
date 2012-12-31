module Eye::Utils
  autoload :WithActor, 'eye/utils/with_actor'
  autoload :MHash,     'eye/utils/mhash'
  autoload :Tail,      'eye/utils/tail'

  def self.async_and_wait(&block)
    # TODO: add pool?
    wa = WithActor.new
    wa.with{ block.call }
  ensure
    wa.terminate if wa.alive?
  end
end