def proc5(proxy, name)
  proxy.process(name){ pid_file "#{name}.pid5" }
end