require 'murmur3'

module Clandestined
  class RendezvousHash

    include Murmur3

    attr_reader :nodes
    attr_reader :seed
    attr_reader :hash_function

    def initialize(nodes=nil, seed=0)
      @nodes = nodes || []
      @seed = seed

      @hash_function = lambda { |key| murmur3_32(key, seed) }

    end

    def add_node(node)
      @nodes.push(node) unless @nodes.include?(node)
    end

    def remove_node(node)
      if @nodes.include?(node)
        @nodes.delete(node)
      else
        raise ArgumentError, "No such node #{node} to remove"
      end
    end

    def find_node(key)
      nodes.max {|a,b| hash_function.call("#{a}-#{key}") <=> hash_function.call("#{b}-#{key}")}
    end

  end
end
