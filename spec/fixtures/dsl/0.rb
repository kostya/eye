require File.expand_path(File.join(File.dirname(__FILE__), %w{1.rb}))

Eye.application("bla") do
  working_dir "/tmp"

  process_1(self, "11")
  process_1(self, "12")
end
