require 'rake/testtask'
require 'rake/extensiontask'

def can_compile_extensions
  if defined? RUBY_DESCRIPTION
    if RUBY_DESCRIPTION =~ /jruby/
      false
    else
      true
    end
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

task :test_docs do
  system("rubydoctest README.md") or exit!(1)
end

if can_compile_extensions
  task :default => [:compile, :test, :test_docs]
else
  task :default => [:test, :test_docs]
end
