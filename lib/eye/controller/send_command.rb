module Eye::Controller::SendCommand

  def send_command(command, *obj_strs)
    matched_objects(*obj_strs) do |obj|
      if command.to_sym == :delete
        remove_object_from_tree(obj) 

        set_proc_line
        save_cache
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
      @current_config.delete_app(obj.name)
    end

    if klass == Eye::Group
      @applications.each{|app| app.groups.delete(obj) }
      @current_config.delete_group(obj.name)
    end

    if klass == Eye::Process
      @applications.each{|app| app.groups.each{|gr| gr.processes.delete(obj) }}
      @current_config.delete_process(obj.name)
    end    
  end

  # find object to action, restart ... (app, group or process)
  # nil if not found
  def find_objects(*obj_strs)
    return [] if obj_strs.blank?
    return @applications.dup if obj_strs.size == 1 && (obj_strs[0].strip == 'all' || obj_strs[0].strip == '*')

    res = Eye::Utils::AliveArray.new
    obj_strs.map{|c| c.split(",")}.flatten.each do |mask|
      res += find_objects_by_mask(mask.to_s.strip)
    end
    res
  end

  def find_objects_by_mask(mask)
    res = find_all_objects_by_mask(mask)

    if res.size > 1
      final = Eye::Utils::AliveArray.new

      if mask[-1] != '*'
        # try to find exactly matched
        r = right_regexp(mask)
        res.each do |obj|
          final << obj if obj.full_name =~ r
        end
      end

      return final if final.present?

      # remove inherited targets
      res.each do |obj|
        sub_object = res.any?{|a| a.sub_object?(obj) }
        final << obj unless sub_object
      end

      res = final
    end    

    res
  end

  def find_all_objects_by_mask(mask)
    res = Eye::Utils::AliveArray
    r = left_regexp(mask)

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

          # child matching
          if p.childs.present?
            childs = p.childs.values
            res += childs.select do |ch|
              name = ch.name rescue ''
              full_name = ch.full_name rescue ''
              name =~ r || full_name =~ r
            end
          end

        end
      end
    end

    res
  end

  def left_regexp(mask)
    str = Regexp.escape(mask).gsub('\*', '.*?')
    %r|\A#{str}|
  end

  def right_regexp(mask)
    str = Regexp.escape(mask).gsub('\*', '.*?')
    %r|#{str}\z|
  end
end
