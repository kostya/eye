Eye.load("./subfolder2/sub/*.rb")
Eye.load("subfolder2/*.rb")

Eye.application "subfolder" do
  working_dir "/tmp"

  proc2 self, "e2"  
  proc3 self, "e3"  
end