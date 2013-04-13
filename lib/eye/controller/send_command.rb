module Eye::Controller::SendCommand

  def send_command(command, *obj_strs)
    matched_objects(*obj_strs) do |obj|
      if command.to_sym == :delete
        remove_object_from_tree(obj) 
        set_proc_line # to sync proc line if was delete application
      end

      obj.send_command(command)
    end
  end

  def match(*obj_strs)
    matched_objects(*obj_strs)
  end  

  def signal(sig, *obj_strs)
    matched_objects(*obj_strs) do |obj|
      obj.send_command :signal, sig || 0
    end
  end

  def break_chain(*obj_strs)
    matched_objects(*obj_strs) do |obj|
      obj.send_command(:break_chain)
    end
  end

private

  def matched_objects(*obj_strs, &block)
    objs = find_objects(*obj_strs)
    res = objs.map(&:full_name)
    objs.each{|obj| block[obj] } if block
    res    
  end

  def remove_object_from_tree(obj)
    klass = obj.class

    if klass == Eye::Application
      @applications.delete(obj)
      @current_config[:applications].delete(obj.name)
    end

    if klass == Eye::Group
      @applications.each{|app| app.groups.delete(obj) }
      @current_config[:applications].each do |app_name, app_cfg|
        app_cfg[:groups].delete(obj.name)
      end
    end

    if klass == Eye::Process
      @applications.each{|app| app.groups.each{|gr| gr.processes.delete(obj) }}

      @current_config[:applications].each do |app_name, app_cfg|
        app_cfg[:groups].each do |gr_name, gr_cfg|
          gr_cfg[:processes].delete(obj.name)
        end
      end
    end    
  end

  # find object to action, restart ... (app, group or process)
  # nil if not found
  def find_objects(*obj_strs)
    return [] if obj_strs.blank?
    return @applications.dup if obj_strs.size == 1 && (obj_strs[0].strip == 'all' || obj_strs[0].strip == '*')

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

    res.present? ? Eye::Utils::AliveArray.new(res) : []
  end

  def find_objects_by_mask(mask)
    mask.strip!

    res = []
    str = Regexp.escape(mask).gsub('\*', '.*?')
    r = %r{\A#{str}}

    # find app
    res = @applications.select{|a| a.name =~ r || a.full_name =~ r }

    # find group
    @applications.each do |a|
      res += a.groups.select{|gr| gr.name =~ r || gr.full_name =~ r }
    end

    # find process
    @applications.each do |a|
      a.groups.each do |gr|
        gr.processes.each do |p|
          res << p if p.name =~ r || p.full_name =~ r

          if p.childs.present?
            res += p.childs.values.select{|ch| ch.name =~ r || ch.full_name =~ r }
          end
        end
      end
    end

    res
  end

end
