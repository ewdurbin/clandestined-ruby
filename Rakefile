require "bundler/gem_tasks"
require 'rake/testtask'
require 'rake/extensiontask'

Rake::ExtensionTask.new('murmur3_native')

Rake::TestTask.new do |t|
  t.libs << "ext"
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
end
