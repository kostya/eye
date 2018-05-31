Eye.app :__default__ do
  trigger :stop_children
  check :memory, below: 10
end
