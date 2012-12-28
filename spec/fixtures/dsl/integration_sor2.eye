Eye.app("int") do
  stop_on_remove true # !!!

  working_dir File.join(File.dirname(__FILE__), %w{.. .. example})
  stdall "shlak.log"

  group "samples" do
    process("sample1") do
      pid_file "1.pid"
      start_command "ruby sample.rb"
      daemonize true
    end

    process("sample2") do
      pid_file "2.pid"
      start_command "ruby sample.rb -d --pid 2.pid --log shlak.log"
      checks :memory, :below => 300.megabytes
    end

    process("sample3") do
      pid_file "3.pid"
      start_command "ruby sample.rb"
      daemonize true
    end    
  end

end