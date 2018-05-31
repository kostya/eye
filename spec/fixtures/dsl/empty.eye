Eye.application('bla') do
  environment 'RAILS_ENV' => 'production'
  keep_alive false
  stdall '12.log'

  group('ha') do
    5.times do |i|
      process("ha_#{i}") do
        environment 'HA' => '1'
        pid_file "/tmp/#{i}"
        stdout '11.log'
      end
    end
  end

  process('1') do
    pid_file '1'
    stdall '1'
  end
end
