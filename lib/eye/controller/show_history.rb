module Eye::Controller::ShowHistory

  def history_string(*obj_strs)
    data = history_data(*obj_strs)

    res = []
    data.each do |name, data|
      res << detail_process_info(name, data)
    end

    res * "\n"
  end

  def history_data(*obj_strs)
    res = {}
    get_processes_for_history(*obj_strs).each do |process|
      res[process.full_name] = process.schedule_history.reject{|c| c[:state] == :check_crash }
    end
    res
  end

private

  def get_processes_for_history(*obj_strs)
    res = []
    matched_objects(*obj_strs) do |obj|
      if (obj.is_a?(Eye::Process) || obj.is_a?(Eye::ChildProcess))
        res << obj
      else
        res += obj.processes.to_a
      end
    end
    Eye::Utils::AliveArray.new(res)
  end

  def detail_process_info(name, history)
    return if history.empty?

    res = "\033[1m#{name}\033[0m:\n"
    history = history.reverse

    history.chunk{|h| [h[:state], h[:reason].to_s] }.each do |_, hist|
      if hist.size >= 3
        res << detail_process_info_string(hist[0])
        res << detail_process_info_string(:state => "... #{hist.size - 2} times", :reason => '...', :at => hist[-1][:at])
        res << detail_process_info_string(hist[-1])
      else
        hist.each do |h|
          res << detail_process_info_string(h)
        end
      end
    end

    res
  end

  def detail_process_info_string(h)
    state = h[:state].to_s.ljust(14)
    "#{Time.at(h[:at]).to_s(:db)} - #{state} (#{h[:reason]})\n"
  end

end