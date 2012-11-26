Eye.load(File.dirname(__FILE__) + "/1*.rb")

Eye.application("bla") do |app|
  working_dir "/tmp"

  process_1(app, "11")
  process_1(app, "12")
end
