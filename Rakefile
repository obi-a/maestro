task :console do
  ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'Ragios'))
  ragios_lib = "#{ragios_dir}/lib/ragios"
  irb = "bundle exec pry -r #{ragios_lib}"
  sh irb
end

task :spec do
  sh 'rspec spec/'
end

task :notifiers do
  sh 'rspec -fs spec/notifiers'
end

task :plugins do
  sh 'rspec -fs spec/plugins'
end

task :unit do
  sh 'rspec -fs spec/unit_tests'
end

task :integration do
  sh 'rspec -fs spec/integration'
end

task :test_ragios do
  #sh 'rspec -fs spec/unit_tests'
  #sh 'rspec -fs spec/integration'
  sh 'rspec spec/lib --format documentation'
end

#task :c => :console
#task :test_notifiers => :notifiers
#task :test_plugins => :plugins
#task :test_unit => :unit
#task :test_integration => :integration

task :test => :test_ragios
task :default => :test_ragios
