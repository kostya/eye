# send notify when many times crashed process, finally resolved

class Eye::Trigger::FixCrash < Eye::Trigger::Custom

  param :times, Integer, nil, 1
  param_default :to, :up

  def check(_)
    # process states here like this: [..., :starting, :down, :starting, :down, :starting, :up]
    states = process.states_history.states

    # states to compare with
    compare = [:starting, :down] * times + [:starting, :up]

    if states[-compare.length..-1] == compare
      process.notify(:info, 'yahho, process up')
    end
  end

end

Eye.app :custom_trigger do
  trigger :fix_crash

  process :some do
    pid_file '/tmp/custom_trigger_some.pid'
    start_command "ruby -e 's = `cat /tmp/bla`; exit(1) unless s =~ /bla/; loop { sleep 1 } '"
    daemonize!
  end
end
