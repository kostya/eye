Eye.load("./subfolder3/**/*.rb")

Eye.application "subfolder" do
  working_dir "/tmp"

  proc4 self, "e1"  
  proc5 self, "e2"  
end