require 'murmur3_native'

class RendezvousHash

  include Murmur3Native

  attr_reader :nodes
  attr_reader :hash_function

  def initialize(nodes=nil, hash_function=method(:murmur3_32))
    @nodes = nodes || []
    @hash_function = hash_function
  end

  def add_node(node)
    @nodes.push(node) unless @nodes.include?(node)
  end

  def remove_node(node)
    @nodes.delete(node) if @nodes.include?(node)
  end

  def find_node(key)
    @nodes.max {|a,b| @hash_function.call("#{a}-#{key}") <=> @hash_function.call("#{b}-#{key}")}
  end

end
