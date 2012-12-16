def proc2(proxy, name)
  proxy.process(name){ pid_file "#{name}.pid2" }
end