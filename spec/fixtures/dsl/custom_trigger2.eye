class DeleteFileEvent < Eye::Trigger::Custom
  param :file, [String], true
  param :on, [Symbol]

  def check(transition)
    if transition.event == on
      info "rm #{file}"
      File.delete(file)
    end
  end
end

Eye.application("bla") do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[.]))
  process("1") do
    pid_file "1.pid"
    start_command "sleep 30"
    daemonize true
    trigger :delete_file_event, :file => "#{self.working_dir}/1.tmp", :on => :crashed
  end
end
