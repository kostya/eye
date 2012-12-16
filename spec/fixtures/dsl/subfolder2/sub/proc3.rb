def proc3(proxy, name)
  proxy.process(name){ pid_file "#{name}.pid3" }
end