require "bundler/gem_tasks"

task :default => 'nebula:spec'

namespace :nebula do
  task :console do
    sh 'irb -Ilib -r nebula'
  end

  task :spec do
    exec 'rspec'
  end
end
