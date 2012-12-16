def proc1(proxy, name)
  proxy.process(name){ pid_file "#{name}.pid" }
end