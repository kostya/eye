require 'celluloid'

class Eye::Group

  include Celluloid

  autoload :Call,     'eye/group/call'
  autoload :Chain,    'eye/group/chain'
  autoload :Data,     'eye/group/data'

  include Eye::Process::Scheduler
  include Eye::Group::Call
  include Eye::Group::Chain
  include Eye::Group::Data

  attr_reader :processes, :name, :hidden, :config

  def initialize(name, config)
    @name = name
    @config = config
    @processes = Eye::Utils::AliveArray.new
    @hidden = (name == '__default__')
    debug { 'created' }
  end

  def logger_tag
    full_name
  end

  def app_name
    @config[:application]
  end

  def full_name
    @full_name ||= "#{app_name}:#{@name}"
  end

  def add_process(process)
    @processes << process
  end

  # sort processes in name order
  def resort_processes
    @processes = @processes.sort_by(&:name)
  end

  def clear
    @processes = Eye::Utils::AliveArray.new
  end

  def sub_object?(obj)
    @processes.include?(obj)
  end

  # to sort groups
  def <=>(other)
    if hidden
      1
    elsif other.hidden
      -1
    else
      name <=> other.name
    end
  end

end
