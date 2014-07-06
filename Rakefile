require "bundler/gem_tasks"
require 'rake/testtask'
require 'rake/extensiontask'

def can_compile_extensions
  if defined? RUBY_DESCRIPTION
    false if RUBY_DESCRIPTION =~ /jruby/
  else
    true
  end
end

Rake::ExtensionTask.new('murmur3_native')

Rake::TestTask.new do |t|
  t.libs << "ext"
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
end


if can_compile_extensions
  task :default => [:compile, :test]
else
  task :default => [:test]
end
