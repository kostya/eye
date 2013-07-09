Eye.load("./subfolder2/sub/*.rb")
Eye.load("subfolder2/*.rb")

Eye.application "subfolder2" do
  working_dir "/tmp"

  proc2 self, "e3"
  proc3 self, "e4"
end