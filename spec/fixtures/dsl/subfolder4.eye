Eye.load("./subfolder4/a.rb")
Eye.load("./subfolder4/c.rb")

Eye.application "subfolder4" do
  env 'a' => A, 'b' => B, 'c' => D
end