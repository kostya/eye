module Eye::Controller::Helpers

  def set_proc_line
    str = Eye::PROCLINE
    str += " (#{@applications.map(&:name) * ', '})" if @applications.present?
    str += " [#{ENV['EYE_V']}]" if ENV['EYE_V']
    $0 = str
  end

  def save_cache
    File.open(Eye::Settings.cache_path, 'w') { |f| f.write(cache_str) }
  rescue => ex
    warn "save cache crashed with #{ex.message}"
  end

  def cache_str
    all_processes.map{ |p| "#{p.full_name}=#{p.state}" } * "\n"
  end

  def process_by_name(name)
    all_processes.detect{|c| c.name == name}
  end

  def process_by_full_name(name)
    all_processes.detect{|c| c.full_name == name }
  end

  def group_by_name(name)
    all_groups.detect{|c| c.name == name}
  end

  def application_by_name(name)
    @applications.detect{|c| c.name == name}
  end

  def all_processes
    processes = []
    all_groups.each do |gr|
      processes += gr.processes.to_a
    end

    processes
  end

  def all_groups
    groups = []
    @applications.each do |app|
      groups += app.groups.to_a
    end

    groups
  end

  # {'app_name' => {'group_name' => {'process_name' => 'pid_file'}}}
  def short_tree
    res = {}
    @applications.each do |app|
      res2 = {}

      app.groups.each do |group|
        res3 = {}

        group.processes.each do |process|
          res3[process.name] = process[:pid_file_ex]
        end

        res2[group.name] = res3
      end

      res[app.name] = res2
    end

    res
  end

end
