# http://stackoverflow.com/questions/7263268/ruby-symbolto-proc-leaks-references-in-1-9-2-p180

unless defined?(SimpleCov) # simplecov somehow crashed with this

  class Symbol
    def to_proc
      lambda { |x| x.send(self) }
    end
  end
end