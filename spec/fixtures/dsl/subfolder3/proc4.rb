def proc4(proxy, name)
  proxy.process(name){ pid_file "#{name}.pid4" }
end