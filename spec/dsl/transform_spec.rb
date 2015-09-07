require File.dirname(__FILE__) + '/../spec_helper'

describe "transform dsl" do

  describe "syslog" do

    it "daemonized processes" do
      conf = <<-E
        Eye.application("bla") do
          process("a") do
            daemonize!
            start_command %q|ruby -e 'loop { sleep 1; STDOUT.puts "a"; STDERR.puts "a"; } '|
            pid_file "/tmp/a"
            stdall syslog
          end

          group :gr do
            process("b") do
              daemonize!
              start_command "ruby -e 'loop { sleep 1; STDOUT.puts \\"b\\"; STDERR.puts \\"b\\"; } '"
              pid_file "/tmp/b"
              stdall syslog
            end
          end

          process("c") do
            daemonize!
            start_command %q|ruby -e "loop { sleep 1; STDOUT.puts 'c'; STDERR.puts 'c'; } "|
            pid_file "/tmp/c"
            stdall syslog
          end

          process("d") do
            daemonize!
            start_command "ruby -e 'loop { sleep 1; STDOUT.puts \\"d\\"; STDERR.puts \\"d\\"; } '"
            pid_file "/tmp/d"
            stdout syslog
            stderr "/tmp/d.log"
          end
        end
      E

      h = {"bla" => {:name=>"bla", :groups=>{
        "__default__"=>{:name=>"__default__", :application=>"bla", :processes=>{
          "a"=>{:name=>"a", :application=>"bla", :group=>"__default__", :daemonize=>true,
            :start_command=>"sh -c \"ruby -e 'loop { sleep 1; STDOUT.puts \\\"a\\\"; STDERR.puts \\\"a\\\"; } ' 2>&1 | logger -t \"bla:a\"\"",
            :pid_file=>"/tmp/a", :stdall=>":syslog", :stdout=>nil, :stderr=>nil, :use_leaf_child=>true},
          "c"=>{:name=>"c", :application=>"bla", :group=>"__default__", :daemonize=>true,
            :start_command=>"sh -c \"ruby -e \\\"loop { sleep 1; STDOUT.puts 'c'; STDERR.puts 'c'; } \\\" 2>&1 | logger -t \"bla:c\"\"",
            :pid_file=>"/tmp/c", :stdall=>":syslog", :stdout=>nil, :stderr=>nil, :use_leaf_child=>true},
          "d"=>{:name=>"d", :application=>"bla", :group=>"__default__", :daemonize=>true,
            :start_command=>"sh -c \"ruby -e 'loop { sleep 1; STDOUT.puts \\\"d\\\"; STDERR.puts \\\"d\\\"; } '  | logger -t \"bla:d\"\"",
            :pid_file=>"/tmp/d", :stdout=>nil, :stderr=>"/tmp/d.log", :use_leaf_child=>true}}},
        "gr"=>{:name=>"gr", :application=>"bla", :processes=>{
          "b"=>{:name=>"b", :application=>"bla", :group=>"gr", :daemonize=>true,
            :start_command=>"sh -c \"ruby -e 'loop { sleep 1; STDOUT.puts \\\"b\\\"; STDERR.puts \\\"b\\\"; } ' 2>&1 | logger -t \"bla:gr:b\"\"",
            :pid_file=>"/tmp/b", :stdall=>":syslog", :stdout=>nil, :stderr=>nil, :use_leaf_child=>true}}}}}}

      Eye::Dsl.parse_apps(conf).should == h
    end

    it "non daemonized processes" do
      conf = <<-E
        Eye.application("bla") do
          process("a") do
            start_command %q|some_script -d --pid_file '/tmp/a'|
            pid_file "/tmp/a"
            stdall syslog
          end
        end
      E

      h = {"bla" => {:name=>"bla", :groups=>{
        "__default__"=>{:name=>"__default__", :application=>"bla", :processes=>{
          "a"=>{:name=>"a", :application=>"bla", :group=>"__default__",
            :start_command=>"sh -c \"some_script -d --pid_file '/tmp/a' 2>&1 | logger -t \"bla:a\"\"",
            :pid_file=>"/tmp/a", :stdall=>":syslog", :stdout=>nil, :stderr=>nil}}}}}}

      Eye::Dsl.parse_apps(conf).should == h
    end

  end
end