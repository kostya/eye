class Eye::Controller::Load::Result
  def should_be_ok(files_count = 1)
    self.size.should == files_count
    self.values.count{ |res| res[:error] }.should == 0
  end

  def ok_count
    self.values.count{ |res| !res[:error] }
  end  

  def errors_count
    self.values.count{ |res| res[:error] }
  end  

  def res
    if self.size == 1
      self.values.first
    else
      raise "incorrect res using: #{self.size}"
    end
  end

  def match(pattern)
    keys = self.keys.grep(pattern)
    if keys.size == 1
      key = keys.first
      self[key]
    else
      raise "incorrect pattern: matching #{keys.size}"
    end
  end
end
