require File.dirname(__FILE__) + '/../spec_helper'

describe "Syncer" do
  
  before :each do
    start_controller do
      @controller.load_erb(fixture("dsl/syncer.erb"))
    end
  end

  after :each do
    stop_controller
  end

  describe "process" do
    it "restart process" do
      should_spend(3, 0.5) do
        Eye::Utils::Syncer.with do |c|
          @controller.command(:restart, "sample1", :syncer => c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 0
    end

    it "restart 2 processes" do
      should_spend(4.2, 1.0) do
        Eye::Utils::Syncer.with do |c|
          @controller.command(:restart, "sample1", "sample2", :syncer => c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
    end

    it "without syncer it should spend 0" do
      should_spend(0, 0.3) do
        @controller.command(:restart, "sample1", "sample2")
      end

      sleep 5

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
    end

    it "delete" do
      process = @controller.process_by_name 'bla1-sleep-0'

      should_spend(0.7, 0.4) do
        Eye::Utils::Syncer.with do |s|
          process.send_call(command: :delete, syncer: s)
        end
      end
    end    
  end

  describe "group" do
    it "stop" do
      group = @controller.group_by_name 'samples'

      should_spend(0.5, 0.2) do
        group.sync_call(command: :stop)
      end

      @p1.state_name.should == :unmonitored
      @p2.state_name.should == :unmonitored
      @p3.state_name.should == :up
    end    

    it "restart" do
      group = @controller.group_by_name 'samples'

      should_spend(3.8, 0.5) do
        group.sync_call(command: :restart)
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
      @p3.states_history.states.count { |s| s == :restarting }.should == 0
    end    

    it "restart from controller" do
      should_spend(4.0, 0.7) do
        Eye::Utils::Syncer.with do |c|
          @controller.command(:restart, "samples", syncer: c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
      @p3.states_history.states.count { |s| s == :restarting }.should == 0
    end

    it "sync chain async" do
      group = @controller.group_by_name 'bla1'

      should_spend(5.0, 1.0) do
        group.sync_call(command: :restart)
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 0
      @p2.states_history.states.count { |s| s == :restarting }.should == 0
      @p3.states_history.states.count { |s| s == :restarting }.should == 0
      @controller.process_by_name('bla1-sleep-0').states_history.states.count { |s| s == :restarting }.should == 1
      @controller.process_by_name('bla2-sleep-0').states_history.states.count { |s| s == :restarting }.should == 0
    end

    it "sync chain sync" do
      group = @controller.group_by_name 'bla2'

      should_spend(7, 3.0) do
        group.sync_call(command: :restart)
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 0
      @p2.states_history.states.count { |s| s == :restarting }.should == 0
      @p3.states_history.states.count { |s| s == :restarting }.should == 0
      @controller.process_by_name('bla1-sleep-0').states_history.states.count { |s| s == :restarting }.should == 0
      @controller.process_by_name('bla2-sleep-0').states_history.states.count { |s| s == :restarting }.should == 1
    end

    it "delete" do
      group = @controller.group_by_name 'samples'

      should_spend(0, 0.1) do
        group.sync_call(command: :delete)
      end

      group.alive?.should == false
    end

    it "delete group and process have stop_on_delete true" do
      group = @controller.group_by_name 'bla1'

      should_spend(0.7, 0.3) do
        Eye::Utils::Syncer.with do |s|
          @controller.command(:delete, 'bla1', syncer: s)
        end
      end

      group.alive?.should == false
    end

    it "restart groups in parallel" do
      group1 = @controller.group_by_name 'bla1'
      group2 = @controller.group_by_name 'bla2'

      should_spend(6.5, 1.0) do
        Eye::Utils::Syncer.new.wait_group do |g|
          group1.send_call(command: :restart, syncer: g.child)
          group2.send_call(command: :restart, syncer: g.child)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 0
      @p2.states_history.states.count { |s| s == :restarting }.should == 0
      @p3.states_history.states.count { |s| s == :restarting }.should == 0
      @controller.process_by_name('bla1-sleep-0').states_history.states.count { |s| s == :restarting }.should == 1
      @controller.process_by_name('bla2-sleep-0').states_history.states.count { |s| s == :restarting }.should == 1
    end
  end

  describe "application" do
    it "stop" do
      app = @controller.application_by_name 'int'

      should_spend(1.2, 0.4) do
        Eye::Utils::Syncer.with(30) do |c|
          app.send_call(command: :stop, syncer: c)
        end
      end

      @p1.state_name.should == :unmonitored
      @p2.state_name.should == :unmonitored
      @p3.state_name.should == :unmonitored
    end    

    it "restart" do
      app = @controller.application_by_name 'int'

      should_spend(7, 2.0) do
        Eye::Utils::Syncer.with(30) do |c|
          app.send_call(command: :restart, syncer: c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
      @p3.states_history.states.count { |s| s == :restarting }.should == 1
    end

    it "restart from controller" do
      should_spend(7, 2.0) do
        Eye::Utils::Syncer.with do |c|
          @controller.command(:restart, "int", syncer: c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
      @p3.states_history.states.count { |s| s == :restarting }.should == 1
    end
  end 

  describe "mixed" do
    it "restart group and process" do
      should_spend(4.7, 1.0) do
        Eye::Utils::Syncer.with do |c|
          @controller.command(:restart, "samples", "forking", syncer: c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 1
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
      @p3.states_history.states.count { |s| s == :restarting }.should == 1
    end

    it "restart 2 processes" do
      should_spend(5.0, 1.2) do
        Eye::Utils::Syncer.with do |c|
          @controller.command(:restart, "sample2", "forking", syncer: c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 0
      @p2.states_history.states.count { |s| s == :restarting }.should == 1
      @p3.states_history.states.count { |s| s == :restarting }.should == 1
    end

    it "bla1 and bla2" do
      should_spend(7, 2.0) do
        Eye::Utils::Syncer.with do |c|
          @controller.command(:restart, "bla1", "bla2", syncer: c)
        end
      end

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.states_history.states.count { |s| s == :restarting }.should == 0
      @p2.states_history.states.count { |s| s == :restarting }.should == 0
      @p3.states_history.states.count { |s| s == :restarting }.should == 0
    end
  end

end
