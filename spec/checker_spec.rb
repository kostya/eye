# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper'

class Checker1 < Eye::Checker

  def get_value
    true
  end

  def good?(value)
    value
  end
end

describe "Eye::Checker" do

  it "defaults" do
    @c = Checker1.new(1, {:times => 3})
    @c.max_tries.should == 3
    @c.min_tries.should == 3
  end

  it "defaults" do
    @c = Checker1.new(1, {:times => [3, 5]})
    @c.max_tries.should == 5
    @c.min_tries.should == 3
  end

  it "defaults" do
    @c = Checker1.new(1, {})
    @c.max_tries.should == 1
    @c.min_tries.should == 1
  end

  describe "one digit" do
    before :each do
      @c = Checker1.new(1, {:times => 3, :bla => 1})
    end

    it "times 3 from 3" do
      @c.check.should == true
      @c.check.should == true
      @c.check.should == true
      @c.check.should == true
    end

    it "times 3 from 3" do
      stub(@c).get_value{true}
      @c.check.should == true
      stub(@c).get_value{false}
      @c.check.should == true
      stub(@c).get_value{false}
      @c.check.should == true

      stub(@c).get_value{true}
      @c.check.should == true
    end

    it "times 3 from 3" do
      stub(@c).get_value{true}
      @c.check.should == true
      stub(@c).get_value{false}
      @c.check.should == true
      stub(@c).get_value{false}
      @c.check.should == true

      stub(@c).get_value{false}
      @c.check.should == false
    end

  end

  describe "two digits" do
    before :each do
      @c = Checker1.new(1, {:times => [2,5], :bla => 1})
    end

    it "2 from 5" do
      @c.check.should == true
      @c.check.should == true
      @c.check.should == true
      @c.check.should == true
      @c.check.should == true
      @c.check.should == true
    end

    it "times 2 from 5" do
      stub(@c).get_value{true}
      @c.check.should == true
      stub(@c).get_value{false}
      @c.check.should == true
      stub(@c).get_value{true}
      @c.check.should == true

      stub(@c).get_value{true}
      @c.check.should == true

      stub(@c).get_value{true}
      @c.check.should == true

      stub(@c).get_value{true}
      @c.check.should == true
    end


    it "times 2 from 5" do
      stub(@c).get_value{true}
      @c.check.should == true
      stub(@c).get_value{false}
      @c.check.should == true
      stub(@c).get_value{false}
      @c.check.should == true

      stub(@c).get_value{true}
      @c.check.should == true

      stub(@c).get_value{true}
      @c.check.should == false

      stub(@c).get_value{true}
      @c.check.should == false

      stub(@c).get_value{true}
      @c.check.should == true
    end
  end

end
