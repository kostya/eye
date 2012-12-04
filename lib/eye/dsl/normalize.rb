module Eye::Dsl::Normalize

  # join options with proxies
  def normalized_config(config)
    new_config = {}

    config.each do |app, app_cfg|
      next if app_cfg.blank?

      groups = app_cfg.delete(:groups) || {}

      ngroups = {}
      groups.each do |group_name, group_cfg|
        next if group_cfg.blank?
        processes = group_cfg.delete(:processes) || {}

        nprocesses = {}

        processes.each do |pname, p_cfg|
          next if p_cfg.blank?

          new_pcfg = merge_hash(merge_hash(app_cfg, group_cfg), p_cfg)
          new_pcfg.merge!(:application => app, :group => group_name, :name => pname)
          nprocesses[pname] = new_pcfg
        end

        ngroups[group_name] = merge_hash(app_cfg, group_cfg).update(:processes => nprocesses)
      end

      new_config[app] = app_cfg.update(:groups => ngroups)
    end

    new_config
  end

  # hash crazy merging
  def merge_hash(first, second)
    result = first.clone

    second.each do |key, value|
      if first[key]        
        if first[key].is_a?(Hash)
          result[key] = first[key].merge(value)
        else
          result[key] = value
        end
      else
        result[key] = value
      end
    end

    result
  end

end
