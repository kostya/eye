module Eye::Controller::Apply

  def apply(masks, call)
    res = matched_objects(*masks) do |obj|
      if call[:command].to_sym == :delete
        remove_object_from_tree(obj)
        set_proc_line
      end
    end

    objs = res.delete(:objects)
    async.apply_to_objects(objs, call) if objs
    res
  end

  def match(*args)
    matched_objects(*args)
  end

private

  def apply_to_objects(objs, call)
    # TODO: if signal, create multiple signals?
    objs.each do |obj|
      obj.send_call(call)
    end
  end

  class Error < RuntimeError; end

  def matched_objects(*args, &block)
    objs = find_objects(*args)
    res = objs.map(&:full_name)
    objs.each { |obj| block[obj] } if block
    { result: res, objects: objs }

  rescue Error => ex
    { error: ex.message }

  rescue Celluloid::DeadActorError => ex
    log_ex(ex)
    { error: "'#{ex.message}', try again!" }
  end

  def remove_object_from_tree(obj)
    klass = obj.class

    if klass == Eye::Application
      @applications.delete(obj)
      @current_config.delete_app(obj.name)
    end

    if klass == Eye::Group
      @applications.each { |app| app.groups.delete(obj) }
      @current_config.delete_group(obj.name)
    end

    if klass == Eye::Process
      @applications.each { |app| app.groups.each { |gr| gr.processes.delete(obj) } }
      @current_config.delete_process(obj.name)
    end
  end

  # find object to action, restart ... (app, group or process)
  # nil if not found
  def find_objects(*args)
    # TODO, why h? for what?
    h = args.extract_options!
    obj_strs = args

    return [] if obj_strs.blank?

    if obj_strs.size == 1 && (obj_strs[0].to_s.strip == 'all' || obj_strs[0].to_s.strip == '*')
      return @applications.dup unless h[:application]
      return @applications.select { |app| app.name == h[:application] }
    end

    res = Eye::Utils::AliveArray.new
    obj_strs.map { |c| c.to_s.split(',') }.flatten.each do |mask|
      objs = find_objects_by_mask(mask.to_s.strip)
      objs.select! { |obj| obj.app_name == h[:application] } if h[:application]
      res += objs
    end
    res
  end

  def find_objects_by_mask(mask)
    res = find_all_objects_by_mask(mask)

    if res.size > 1
      final = Eye::Utils::AliveArray.new

      # try to find exactly matched
      if mask[-1] != '*'
        r = exact_regexp(mask)
        res.each do |obj|
          final << obj if obj.name =~ r || obj.full_name =~ r
        end
      end

      res = final if final.present?
      final = Eye::Utils::AliveArray.new

      # remove inherited targets
      res.each do |obj|
        sub_object = res.any? { |a| a.sub_object?(obj) }
        final << obj unless sub_object
      end

      res = final

      # try to remove objects with different applications
      apps = Eye::Utils::AliveArray.new
      objs = Eye::Utils::AliveArray.new
      res.each do |obj|
        if obj.is_a?(Eye::Application)
          apps << obj
        else
          objs << obj
        end
      end

      return apps unless apps.empty?

      if !mask.start_with?('*') && objs.map(&:app_name).uniq.size > 1
        raise Error, "cannot match targets from different applications: #{res.map(&:full_name)}"
      end
    end

    res
  end

  def find_all_objects_by_mask(mask)
    res = Eye::Utils::AliveArray
    r = left_regexp(mask)

    # find app
    res = @applications.select { |a| a.name =~ r || a.full_name =~ r }

    # find group
    @applications.each do |a|
      res += a.groups.select { |gr| gr.name =~ r || gr.full_name =~ r }
    end

    # find process
    @applications.each do |a|
      a.groups.each do |gr|
        gr.processes.each do |p|
          res << p if p.name =~ r || p.full_name =~ r

          # children matching
          ch = p.children
          next if ch.empty?
          ch.values.each do |child|
            name = child.name rescue ''
            full_name = child.full_name rescue ''
            res << child if name =~ r || full_name =~ r
          end
        end
      end
    end

    res
  end

  def left_regexp(mask)
    str = Regexp.escape(mask).gsub('\*', '.*?')
    %r[\A#{str}]
  end

  def exact_regexp(mask)
    str = Regexp.escape(mask).gsub('\*', '.*?')
    %r[\A#{str}\z]
  end

end
