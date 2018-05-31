Eye.load('./subfolder3/**/*.rb')

Eye.application 'subfolder3' do
  working_dir '/tmp'

  proc4 self, 'e1'
  proc5 self, 'e2'
end
