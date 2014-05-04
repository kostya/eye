require File.dirname(__FILE__) + '/spec_helper'

def join_path(arr)
  File.join(File.dirname(__FILE__), arr)
end

describe "Eye::Local" do
  it "should find_eyefile" do
    Eye::Local.find_eyefile(join_path %w[ fixtures ]).should == nil
    Eye::Local.find_eyefile(join_path %w[]).should == nil

    result = join_path %w[ fixtures dsl Eyefile ]
    Eye::Local.find_eyefile(join_path %w[ fixtures dsl ]).should == result
    Eye::Local.find_eyefile(join_path %w[ fixtures dsl configs ]).should == result
    Eye::Local.find_eyefile(join_path %w[ fixtures dsl subfolder3 sub ]).should == result
  end
end
