class Hash
  def should_be_ok(files_count = 1)
    self.size.should == files_count
    self.errors_count.should == 0
  end

  def ok_count
    self.values.count{ |res| !res[:error] }
  end  

  def errors_count
    self.size - self.ok_count
  end  

  def only_value
    if self.size == 1
      self.values.first
    else
      raise "request for 1 value, but there is more: #{self.size}"
    end
  end

  def only_match(pattern)
    keys = self.keys.grep(pattern)
    if keys.size == 1
      key = keys.first
      self[key]
    else
      raise "incorrect pattern: matched #{keys.size} with #{pattern} (expected only 1)"
    end
  end
end
