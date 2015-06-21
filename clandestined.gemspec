Gem::Specification.new do |s|
  s.name = 'clandestined'
  s.version = '1.0.0'
  s.licenses = ['MIT']
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = 'rendezvous hashing implementation based on murmur3 hash'
  s.author = "Ernest W. Durbin III"
  s.email = 'ewdurbin@gmail.com'
  s.homepage = 'https://github.com/ewdurbin/clandestined-ruby'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
  s.require_paths = ['lib', 'ext']
  s.extensions = ['ext/murmur3_native/extconf.rb']

  if RUBY_VERSION < "1.9"
    s.add_development_dependency 'rake', '0.8.7'
    s.add_development_dependency 'rake-compiler', '0.8.3'
    s.add_development_dependency 'rubydoctest', '1.1.3'
  else
    s.add_development_dependency 'rake'
    s.add_development_dependency 'rake-compiler'
    s.add_development_dependency 'rubydoctest'
    s.add_development_dependency 'test-unit', '3.1.2'
  end

  s.has_rdoc = false

  s.description = <<DESCRIPTION
rendezvous hashing implementation based on murmur3 hash
DESCRIPTION
end
