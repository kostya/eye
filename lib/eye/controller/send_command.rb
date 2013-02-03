module Eye::Controller::SendCommand

  def send_command(command, *obj_strs)
    objs = find_objects(*obj_strs)
    res = objs.map{|obj| obj.full_name }

    objs.each do |obj|
      obj.send_command(command)
      
      if command.to_sym == :delete
        remove_object_from_tree(obj) 
        set_proc_line # to sync proc line if was delete application
        GC.start
      end
    end
    
    res
  end

  def match(*obj_strs)
    find_objects(*obj_strs).map{|obj| obj.full_name }
  end  

private

  def remove_object_from_tree(obj)
    @applications.delete(obj)
    @applications.each{|app| app.groups.delete(obj) }
    @applications.each{|app| app.groups.each{|gr| gr.processes.delete(obj) }}
  end

  # find object to action, restart ... (app, group or process)
  # nil if not found
  def find_objects(*obj_strs)
    return [] if obj_strs.blank?
    return @applications if obj_strs.size == 1 && obj_strs[0].strip == 'all'

    res = obj_strs.map{|c| c.split(",").map{|mask| find_objects_by_mask(mask) }}.flatten

    if res.size > 1
      # remove inherited targets

      final = []
      res.each do |obj|
        sub_object = res.any?{|a| a.sub_object?(obj) }
        final << obj unless sub_object
      end

      res = final
    end

    res.present? ? AliveArray.new(res) : res
  end

  def find_objects_by_mask(mask)
    mask.strip!

    res = []
    str = Regexp.escape(mask).gsub('\*', '.*?')
    r = %r{\A#{str}\z}

    # find app
    res = @applications.select{|a| a.name =~ r || a.full_name =~ r }

    # find group
    @applications.each do |a|
      res += a.groups.select{|gr| gr.name =~ r || gr.full_name =~ r }
    end

    # find process
    @applications.each do |a|
      a.groups.each do |gr|
        res += gr.processes.select{|p| p.name =~ r || p.full_name =~ r }
      end
    end

    res
  end

end