require 'murmur3'
require 'set'

class RendezvousHash

  attr_reader :nodes
  attr_reader :hash_function

  def initialize(nodes=nil, hash_function=method(:murmur3_32_str_hash))
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

class Cluster

  def initialize(cluster, hash_function=method(:murmur3_32_str_hash), replicas=2)
    @hash_function = hash_function

    @replicas = replicas
    @nodes = Hash[]
    @zones = []
    @zone_members = Hash[]
    @zone_members.default = []
    @rings = Hash[]

    cluster.each do |node, node_data|
      name = node_data['name']
      zone = node_data['zone']
      add_zone(zone)
      add_node(node, name, zone)
    end
  end

  def add_zone(zone)
    @zones.push(zone) unless @zones.include?(zone)
    @zones.sort!
  end

  def remove_zone(zone)
    @zones.delete(zone) if @zones.include?(zone)
    @zones.sort!
  end

  def node_name_by_id(node_id)
    @nodes[node_id]
  end

  def add_node(node_id, node_name=nil, node_zone=nil)
    raise ArgumentError, 'Cluster not initialized with zone #{node_zone}' unless @zones.include?(node_zone)
    unless @rings.has_key?(node_zone)
      zone = RendezvousHash.new(nil, @hash_function)
      @rings[node_zone] = zone
    end
    @rings[node_zone].add_node(node_id)
    @nodes[node_id] = node_name unless @nodes.include?(node_id)
    @zone_members[node_zone].push(node_id) unless @zone_members[node_zone].include?(node_id)
  end

  def remove_node(node_id, node_name=nil, node_zone=nil)
    raise ArgumentError, 'Cluster not initialized with zone #{zone}' unless @zones.include?(zone)
    @rings[node_zone].delete(node_id) if @rings.has_key?(node_zone)
    @nodes.delete(node_id) if @nodes.include?(node_id)
    @zone_members[node_zone].delete(node_id) if @zone_members[node_zone].include?(node_id)
  end

  def find_nodes(product_id, block_index)
    nodes = []
    offset = (product_id.to_i + block_index.to_i) % @zones.length
    for i in (0...@replicas)
      zone = @zones[(i + offset) % @zones.length]
      key = "#{product_id}-#{block_index}"
      nodes << @rings[zone].find_node(key)
    end
    nodes
  end

end
