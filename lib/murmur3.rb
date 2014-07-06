begin
  # Extension target, might not exist on some installations
  require 'murmur3_native'
  Murmur3 = Murmur3Native
rescue LoadError
  # Pure Ruby fallback, should cover all methods that are otherwise in extension
  require 'murmur3_ruby'
  Murmur3 = Murmur3Ruby
end
