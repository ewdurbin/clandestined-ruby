require 'murmur3'

module Clandestined
  class RendezvousHash

    include Murmur3

    attr_reader :nodes
    attr_reader :murmur_seed
    attr_reader :hash_function

    def initialize(nodes=nil, murmur_seed=0, hash_function=method(:murmur3_32))
      @nodes = nodes || []
      @murmur_seed = murmur_seed

      if hash_function == method(:murmur3_32)
        @hash_function = lambda { |key| hash_function.call(key, murmur_seed) }
      elsif murmur_seed != 0
        raise ArgumentError, "Cannot apply seed to custom hash function #{hash_function}"
      else
        @hash_function = hash_function
      end

    end

    def add_node(node)
      @nodes.push(node) unless @nodes.include?(node)
    end

    def remove_node(node)
      @nodes.delete(node) if @nodes.include?(node)
    end

    def find_node(key)
      nodes.max {|a,b| hash_function.call("#{a}-#{key}") <=> hash_function.call("#{b}-#{key}")}
    end

  end
end
