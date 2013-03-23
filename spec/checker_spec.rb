require File.dirname(__FILE__) + '/spec_helper'

class Checker1 < Eye::Checker

  def get_value
    true
  end

  def good?(value)
    value
  end
end

class Checker2 < Eye::Checker
  param :bla, [String, Symbol]
  param :bla2, [String, Symbol], true
  param :bla3, [String, Symbol], true, "hi"
  param :bla4, [String, Symbol], false, "hi2"
  param :bla5, [Fixnum, Float]
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

  describe "default validates" do
    it "validate by default" do
      Checker1.validate({:times => 3})
    end

    it "validate by default" do
      expect{ Checker1.validate({:times => "jopa"}) }.to raise_error(Eye::Dsl::Validation::Error)
    end
  end

  it "defaults every" do
    @c = Checker1.new(nil, {:times => 3})
    @c.every.should == 5
  end

  it "not defaults every" do
    @c = Checker1.new(nil, {:times => 3, :every => 10})
    @c.every.should == 10
  end

  describe "validates" do
    it "validate ok" do
      Checker2.validate({:bla2 => :a111})
      Checker2.validate({:bla2 => "111"})
      Checker2.validate({:bla2 => "111", :bla => :bla})
      Checker2.validate({:bla2 => "111", :bla5 => 10.minutes})
      Checker2.validate({:bla2 => "111", :bla5 => 15.4.seconds})

      c = Checker2.new(nil, :bla2 => :a111)
      c.bla.should == nil
      c.bla2.should == :a111
      c.bla3.should == 'hi'
      c.bla4.should == 'hi2'

      c = Checker2.new(nil, :bla2 => :a111, :bla3 => "ho", :bla => 'bla')
      c.bla.should == 'bla'
      c.bla2.should == :a111
      c.bla3.should == 'ho'
      c.bla4.should == 'hi2'
    end

    it "validate bad" do
      expect{ Checker2.validate({}) }.to raise_error
      expect{ Checker2.validate({:bla => :bla}) }.to raise_error
      expect{ Checker2.validate({:bla2 => 123}) }.to raise_error
      expect{ Checker2.validate({:bla2 => :hi, :bla3 => {}}) }.to raise_error
      expect{ Checker2.validate({:bla => :bla, :bla3 => 1, :bla4 => 2}) }.to raise_error
      expect{ Checker2.validate({:bla2 => :hi, :bla5 => []}) }.to raise_error
    end

  end

end