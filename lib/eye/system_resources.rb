require 'celluloid'

class Eye::SystemResources

  # cached system resources
  class << self

    def memory_usage(pid)
      ps_aux[pid].try :[], :rss
    end

    def cpu_usage(pid)
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

    def cpu_usage2(pid)
    end

    MEMORY_REGX = /VmData:\s*([^\s]+)\s/

    # fast
    def memory_usage2(pid)
      data = File.read("/proc/#{pid}/status")
      data.match(MEMORY_REGX)
      $1.to_i
    rescue
      -1
    end

    # initialize actor, call 1 time before using
    def setup
      @actor ||= PsAxActor.new
    end
    
  private
  
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
      set! if @at + UPDATE_INTERVAL < Time.now
      @ps_aux
    end

  private

    def set
      @ps_aux = Eye::System.ps_aux
      @at = Time.now
    end

  end

end