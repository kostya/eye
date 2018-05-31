Eye.application 'app1' do
  group 'gr1' do
    process('p2') { pid_file 'app1-gr1-p2.pid' }
    process('p3') { pid_file 'app1-gr1-p3.pid' }
  end

  group 'gr2' do
    process('p4') { pid_file 'app1-gr2-p4.pid' }
    process('p5') { pid_file 'app1-gr2-p5.pid' }
  end

  process('p0-1') { pid_file 'app1-p0-1.pid' }
end
