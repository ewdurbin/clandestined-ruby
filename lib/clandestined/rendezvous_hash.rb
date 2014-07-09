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
      high_score = -1
      winner = nil
      nodes.each do |node|
        score = hash_function.call("#{node}-#{key}")
        if score > high_score
          high_score, winner = score, node
        elsif score == high_score
          high_score, winner = score, [node.to_s, winner.to_s].max
        end
      end
      winner
    end

  end
end
