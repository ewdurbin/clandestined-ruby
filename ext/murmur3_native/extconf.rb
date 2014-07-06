require 'mkmf'

dir_config("murmur3_native")
have_library("c", "main")

$defs << "-DRUBY_VERSION_CODE=#{RUBY_VERSION.gsub(/\D/, '')}"

create_makefile("murmur3_native")
