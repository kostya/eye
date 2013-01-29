require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Group" do

  describe "correctly chain calls" do
    it "1" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :sync, :command => :start, :grace => 7}}})
      mock(@g).chain(:sync, :start, 7)
      @g.start
    end

    it "1.1" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :async, :command => :start, :grace => 7}}})
      mock(@g).chain(:async, :start, 7)
      @g.start
    end

    it "1.2" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :async, :command => :start, :grace => 7}, :restart => {:type => :sync, :command => :restart, :grace => 8}}})
      mock(@g).chain(:async, :start, 7)
      @g.start

      mock(@g).chain(:sync, :restart, 8)
      @g.restart
    end

    it "2" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :sync, :command => :start}}})
      mock(@g).chain(:sync, :start, 0)
      @g.start
    end

    it "3" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:command => :start}}})
      mock(@g).chain(:async, :start, 0)
      @g.start
    end

    it "4" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:command => :restart}}})
      dont_allow(@g).chain
      @g.restart
    end

    it "4.1" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart}}})
      mock(@g).chain(:async, :restart, 0)
      @g.restart
    end

    it "4.1 bad type" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart, :type => [12324]}}})
      mock(@g).chain(:async, :restart, 0)
      @g.restart
    end

    it "4.1 not valid" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart, :grace => []}}})
      mock(@g).chain(:async, :restart, 0)
      @g.restart
    end

    it "4.1 not valid" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart, :grace => :some_error}}})
      mock(@g).chain(:async, :restart, 0)
      @g.restart
    end

    it "5" do
      @g = Eye::Group.new('gr', {})
      mock(@g).async_all(:restart)
      @g.restart
    end

  end

end