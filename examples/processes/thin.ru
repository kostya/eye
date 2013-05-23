class Test
  def call(env)
    sleep 0.5
    [200, {}, ["Hello World!"]]
  end
end

run Test.new
