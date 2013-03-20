RUBY = 'ruby'
BUNDLE = 'bundle'

Eye.load("process_thin.rb")

Eye.config do
  logger "/tmp/eye.log"
end

Eye.app 'thin-farm' do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  env "RAILS_ENV" => "production"

  stop_on_delete true # this option means, when we change pids and load config, 
                      # deleted processes will be stops

  triggers :flapping, :times => 10, :within => 1.minute
  checks :memory, :below => 60.megabytes, :every => 30.seconds, :times => 5

  group :web do
    chain :action => :restart, :grace => 5.seconds
    chain :action => :start, :grace => 0.2.seconds

    (5555..5560).each do |port|
      thin self, port
    end
  end

end
