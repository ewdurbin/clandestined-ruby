can_compile_extensions = false

begin
  require 'mkmf'
  can_compile_extensions = true
  dir_config("murmur3_native")
  have_library("c", "main")
  $defs << "-DRUBY_VERSION_CODE=#{RUBY_VERSION.gsub(/\D/, '')}"
rescue Exception
  $stderr.puts "Could not require 'mkmf'. Not fatal, the extensions are optional."
end


if can_compile_extensions
  create_makefile("murmur3_native")
else
  mfile = open("Makefile", "wb")
  mfile.puts '.PHONY: install'
  mfile.puts 'install:'
  mfile.puts "\t" + '@echo "Extensions not installed, falling back to pure Ruby version."'
  mfile.close
end
