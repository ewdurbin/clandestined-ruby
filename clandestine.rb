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

  attr_reader :hash_function
  attr_reader :replicas
  attr_reader :nodes
  attr_reader :zones
  attr_reader :zone_members
  attr_reader :rings

  def initialize(cluster=nil, replicas=2, hash_function=method(:murmur3_32_str_hash)) 
    @hash_function = hash_function

    @replicas = replicas
    @nodes = Hash[]
    @zones = []
    @zone_members = Hash[]
    @rings = Hash[]

    if cluster
      cluster.each do |node, node_data|
        name = node_data['name']
        zone = node_data['zone']
        add_zone(zone)
        add_node(node, zone, name)
      end
    end
  end

  def add_zone(zone)
    @zones.push(zone) unless @zones.include?(zone)
    unless @zone_members.has_key?(zone)
      @zone_members[zone] = []
    end
    @zones.sort!
  end

  def remove_zone(zone)
    if @zones.include?(zone)
      @zones.delete(zone)
      for member in @zone_members[zone]
        @nodes.delete(member)
      end
      @zones.sort!
      @rings.delete(zone)
      @zone_members.delete(zone)
    end
  end

  def add_node(node_id, node_zone=nil, node_name=nil)
    if @nodes.include?(node_id)
        raise ArgumentError, 'Node with id #{node_id} already exists'
    end
    add_zone(node_zone)
    unless @rings.has_key?(node_zone)
      @rings[node_zone] = RendezvousHash.new(nil, @hash_function)
    end
    @rings[node_zone].add_node(node_id)
    @nodes[node_id] = node_name
    unless @zone_members.has_key?(node_zone)
      @zone_members[node_zone] = []
    end
    @zone_members[node_zone].push(node_id)
  end

  def remove_node(node_id, node_zone=nil, node_name=nil)
    @rings[node_zone].remove_node(node_id)
    @nodes.delete(node_id)
    @zone_members[node_zone].delete(node_id)
    if @zone_members[node_zone].length == 0
        remove_zone(node_zone)
    end
  end

  def node_name(node_id)
    @nodes[node_id]
  end

  def find_nodes(key, offset=nil)
    nodes = []
    unless offset
      offset = key[0,1].unpack('c')[0]
    end
    for i in (0...@replicas)
      zone = @zones[(i + offset.to_i) % @zones.length]
      nodes << @rings[zone].find_node(key)
    end
    nodes
  end

  def find_nodes_by_index(product_id, block_index)
    offset = (product_id.to_i + block_index.to_i) % @zones.length
    key = "#{product_id}-#{block_index}"
    find_nodes(key, offset)
  end

end
