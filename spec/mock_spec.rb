# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper'

class Aaa
  include Celluloid

  def int
    1
  end

  def ext
    int
  end

end

describe "Actor mocking" do
  before :each do
    @a = Aaa.new    
  end

  it "int" do
    mock(@a).int{2}
    @a.int.should == 2
  end

  it "ext" do
    mock(@a).int{2}
    @a.ext.should == 2
  end

end
