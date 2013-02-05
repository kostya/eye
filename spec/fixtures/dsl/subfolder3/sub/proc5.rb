def proc5(proxy, name)
  proxy.process(name){ 
    working_dir ROOT
    pid_file "#{name}.pid5" 
  }
end