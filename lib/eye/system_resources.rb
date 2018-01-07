require 'celluloid/current'

class Eye::SystemResources

  # cached system resources
  class << self

    def memory(pid)
      if mem = cache.proc_mem(pid)
        mem * 1024
      end
    end

    def cpu(pid)
      cache.proc_cpu(pid)
    end

    def children(parent_pid)
      cache.children(parent_pid)
    end

    def start_time(pid) # unixtime
      if st = cache.proc_start_time(pid)
        Time.parse(st).to_i rescue 0
      end
    end

    # total cpu usage in seconds
    def cputime(_pid)
      0
    end

    # last child in a children tree
    def leaf_child(pid)
      if dc = deep_children(pid)
        dc.detect do |child|
          args = ''
          !args.start_with?('logger') && child != pid
        end
      end
    end

    def deep_children(pid)
      Array(pid_or_children(pid)).flatten.sort_by(&:-@)
    end

    def pid_or_children(pid)
      c = children(pid)
      if !c || c.empty?
        pid
      else
        c.map { |ppid| pid_or_children(ppid) }
      end
    end

    def args(_pid)
      '-'
    end

    def resources(pid)
      { memory: memory(pid),
        cpu: cpu(pid),
        start_time: start_time(pid),
        pid: pid }
    end

    def cache
      Celluloid::Actor[:system_resources_cache]
    end

  end

  class Cache

    include Celluloid

    attr_reader :expire

    def initialize
      clear
      setup_expire
    end

    def setup_expire(expire = 5)
      @expire = expire
      @timer.cancel if @timer
      @timer = every(@expire) { clear }
    end

    def clear
      @ps_aux = nil
    end

    def proc_mem(pid)
      ps_aux[pid].try :[], :rss
    end

    def proc_cpu(pid)
      ps_aux[pid].try :[], :cpu
    end

    def proc_start_time(pid)
      ps_aux[pid].try :[], :start_time
    end

    def children(parent_pid)
      parent_pid = parent_pid.to_i

      childs = []
      ps_aux.each do |pid, h|
        childs << pid if h[:ppid] == parent_pid
      end

      childs
    end

    def ps_aux
      @ps_aux ||= defer { Eye::System.ps_aux }
    end

  end

  # Setup global sigar singleton here
  Cache.supervise(as: :system_resources_cache)

end
