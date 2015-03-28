require File.dirname(__FILE__) + '/../spec_helper'

describe "Custom rspec matchers" do
  it "contain_only" do
    [1,2,9].should contain_only(1, 9, 2)
    [1,2,9].should contain_only(1, 2, 9)
    [1].should contain_only(1)
    [1,2,9].should_not contain_only(1, 2)
    [1,2,9].should_not contain_only(1, 9)
    [1,2,9].should_not contain_only(1, 2, 3)
    [1].should_not contain_only(2)
    [1].should_not contain_only(1, 2)
  end

  it "seq" do
    [1,2,:-,4].should seq(1, 2)
    [1,2,:-,4].should seq(2, :-)
    [1,2,:-,4].should seq(1, 2, :-, 4)
    [1,2,:-,4].should seq(4)
    [1,2,:-,4].should seq(:-, 4)


    [1,2,:-,4].should_not seq(4, :-)
    [1,2,:-,4].should_not seq(5)
    [1,2,:-,4].should_not seq(2, 1)
    [1,2,:-,4].should_not seq(1, 2, :-, 5)
  end
end
