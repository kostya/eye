# Notify example

Eye.config do
  mail :host => "mx.some.host", :port => 25, :domain => "some.host"
  contact :errors, :mail, 'error@some.host'
  contact :dev, :mail, 'dev@some.host'
end

Eye.application :some do
  notify :errors

  process :some_process do
    notify :dev, :warn

    ...
  end

end