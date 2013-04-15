require 'celluloid'

class Eye::SystemResources

  # cached system resources
  class << self

    def memory(pid)
      ps_aux[pid].try :[], :rss
    end

    def cpu(pid)
      ps_aux[pid].try :[], :cpu
    end

    def childs(parent_pid)
      parent_pid = parent_pid.to_i

      childs = []
      ps_aux.each do |pid, h|
        childs << pid if h[:ppid] == parent_pid
      end

      childs
    end

    def cmd(pid)
      ps_aux[pid].try :[], :cmd
    end

    def start_time(pid)
      ps_aux[pid].try :[], :start_time
    end

    def resources(pid)
      return {} unless ps_aux[pid]

      { :memory => memory(pid), 
        :cpu => cpu(pid), 
        :start_time => start_time(pid),
        :cmd => cmd(pid),
        :pid => pid
      }
    end

    # initialize actor, call 1 time before using
    def setup
      @actor ||= PsAxActor.new
    end
    
  private

    def reset!
      setup.terminate
      @actor = nil
    end
  
    def ps_aux
      setup
      @actor.get
    end

  end

  class PsAxActor
    include Celluloid

    UPDATE_INTERVAL = 5 # seconds

    def initialize
      set
    end

    def get
      if @at + UPDATE_INTERVAL < Time.now
        @at = Time.now # for minimize races
        set!
      end
      @ps_aux
    end

  private

    def set
      @ps_aux = defer{ Eye::System.ps_aux }
      @at = Time.now
    end

  end

end