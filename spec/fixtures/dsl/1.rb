def process_1(proxy, name)
  proxy.process(name) do
    pid_file "#{name}.pid"
  end
end