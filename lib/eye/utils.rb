module Eye::Utils
  autoload :WithActor, 'eye/utils/with_actor'
  autoload :MHash,     'eye/utils/mhash'
  autoload :Tail,      'eye/utils/tail'

  def self.defer(&block)
    # TODO: add pool?
    wa = Eye::Utils::WithActor.new
    wa.with{ block.call }
  ensure
    wa.terminate if wa && wa.alive?
  end
end