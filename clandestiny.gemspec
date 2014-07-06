Gem::Specification.new do |s|
  s.name = 'clandestiny'
  s.version = '1.0.0a'
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = 'rendezvous hashing implementation based on murmur3 hash'
  s.author = "Ernest W. Durbin III"
  s.email = 'ewdurbin@gmail.com'
  s.homepage = 'https://github.com/ewdurbin/clandestiny'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
  s.require_paths = ['lib', 'ext']
  s.extensions = ['ext/murmur3_native/extconf.rb']

  s.add_development_dependency 'rake', '0.9.6'
  s.add_development_dependency 'rake-compiler', '0.8.3'

  s.has_rdoc = false

  s.description = <<DESCRIPTION
rendezvous hashing implementation based on murmur3 hash
DESCRIPTION
end
