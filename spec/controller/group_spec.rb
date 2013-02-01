require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Group" do

  describe "Chain calls" do

    it "should call chain_schedule for start" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :async, :command => :start, :grace => 7}}})
      mock(@g).chain_schedule(:async, :start, 7)
      @g.start
    end

    it "should call chain_schedule for start, with type sync" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :sync, :command => :start, :grace => 7}}})
      mock(@g).chain_schedule(:sync, :start, 7)
      @g.start
    end

    it "config for start and restart, use both" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :async, :command => :start, :grace => 7}, :restart => {:type => :sync, :command => :restart, :grace => 8}}})
      mock(@g).chain_schedule(:async, :start, 7)
      @g.start

      mock(@g).chain_schedule(:sync, :restart, 8)
      @g.restart
    end

    it "should use options type" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:type => :sync, :command => :start}}})
      mock(@g).chain_schedule(:sync, :start, Eye::Group::DEFAULT_CHAIN)
      @g.start
    end

    it "with empty grace, should call default grace 0" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:command => :start}}})
      mock(@g).chain_schedule(:async, :start, Eye::Group::DEFAULT_CHAIN)
      @g.start
    end

    it "chain options for restart, but called start, should call chain but with default options" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:command => :restart}}})
      mock(@g).chain_schedule(:async, :restart, Eye::Group::DEFAULT_CHAIN)
      @g.restart
    end

    it "restart without grace, should call default grace 0" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart}}})
      mock(@g).chain_schedule(:async, :restart, Eye::Group::DEFAULT_CHAIN)
      @g.restart
    end

    it "restart with invalid type, should call with async" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart, :type => [12324]}}})
      mock(@g).chain_schedule(:async, :restart, Eye::Group::DEFAULT_CHAIN)
      @g.restart
    end

    it "restart with invalid grace, should call default grace 0" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart, :grace => []}}})
      mock(@g).chain_schedule(:async, :restart, Eye::Group::DEFAULT_CHAIN)
      @g.restart
    end

    it "restart with invalid grace, should call default grace 0" do
      @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart, :grace => :some_error}}})
      mock(@g).chain_schedule(:async, :restart, Eye::Group::DEFAULT_CHAIN)
      @g.restart
    end

    it "restart with empty config, should call chain_schedule" do
      @g = Eye::Group.new('gr', {})
      mock(@g).chain_schedule(:async, :restart, Eye::Group::DEFAULT_CHAIN)
      @g.restart
    end

    it "when chain clearing by force" do
      @g = Eye::Group.new('gr', {:chain => {:start => {:command => :start, :grace => 0}, :restart => {:command => :restart, :grace => 0}}})      
      mock(@g).chain_schedule(:async, :monitor, 0)
      @g.monitor

      mock(@g).chain_schedule(:async, :restart, 0)
      @g.restart

      mock(@g).chain_schedule(:async, :start, 0)
      @g.start
    end

    describe "monitor using chain as start" do
      it "monitor call chain" do
        @g = Eye::Group.new('gr', {:chain => {:start => {:command => :start, :grace => 3}}})
        mock(@g).chain_schedule(:async, :monitor, 3)
        @g.monitor
      end

      it "monitor not call chain" do
        @g = Eye::Group.new('gr', {:chain => {:restart => {:command => :restart, :grace => 3}}})
        mock(@g).chain_schedule(:async, :monitor, Eye::Group::DEFAULT_CHAIN)
        @g.monitor
      end
    end

  end

end