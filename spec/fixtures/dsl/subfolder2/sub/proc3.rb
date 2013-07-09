def proc3(proxy, name)
  proxy.process(name){
    working_dir ROOT
    pid_file "#{name}.pid3"
  }
end