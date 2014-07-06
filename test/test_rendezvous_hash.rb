
require 'test/unit'
require 'set'

require 'clandestine/rendezvous_hash'

def my_hash_function(key)
  return 310130709337150341200260887719094037511
end

class RendezvousHashTestCase < Test::Unit::TestCase

  def test_init_no_options
    rendezvous = RendezvousHash.new()
    assert_equal(0, rendezvous.nodes.length)
    assert_equal(1361238019, rendezvous.hash_function.call('6666'))
  end

  def test_init
    nodes = ['0', '1', '2']
    rendezvous = RendezvousHash.new(nodes)
    assert_equal(3, rendezvous.nodes.length)
    assert_equal(1361238019, rendezvous.hash_function.call('6666'))
  end

  def test_murmur_seed
    rendezvous = RendezvousHash.new(nil, 10)
    assert_equal(2981722772, rendezvous.hash_function.call('6666'))
  end

  def test_custom_hash_function
      rendezvous = RendezvousHash.new(nil, 0, method(:my_hash_function))
      assert_equal(310130709337150341200260887719094037511, rendezvous.hash_function.call('6666'))
  end

  def test_seeded_custom_hash_function
    assert_raises(ArgumentError) { RendezvousHash.new(nil, 10, method(:my_hash_function)) }
  end

  def test_add_node
    rendezvous = RendezvousHash.new()
    rendezvous.add_node('1')
    assert_equal(1, rendezvous.nodes.length)
    rendezvous.add_node('1')
    assert_equal(1, rendezvous.nodes.length)
    rendezvous.add_node('2')
    assert_equal(2, rendezvous.nodes.length)
    rendezvous.add_node('1')
    assert_equal(2, rendezvous.nodes.length)
  end

  def test_remove_node
    nodes = ['0', '1', '2']
    rendezvous = RendezvousHash.new(nodes)
    rendezvous.remove_node('2')
    assert_equal(2, rendezvous.nodes.length)
    rendezvous.remove_node('2')
    assert_equal(2, rendezvous.nodes.length)
    rendezvous.remove_node('1')
    assert_equal(1, rendezvous.nodes.length)
    rendezvous.remove_node('0')
    assert_equal(0, rendezvous.nodes.length)
  end

  def test_find_node
    nodes = ['0', '1', '2']
    rendezvous = RendezvousHash.new(nodes)
    assert_equal('0', rendezvous.find_node('ok'))
    assert_equal('1', rendezvous.find_node('mykey'))
    assert_equal('2', rendezvous.find_node('wat'))
  end

  def test_find_node_after_removal
    nodes = ['0', '1', '2']
    rendezvous = RendezvousHash.new(nodes)
    rendezvous.remove_node('1')
    assert_equal('0', rendezvous.find_node('ok'))
    assert_equal('0', rendezvous.find_node('mykey'))
    assert_equal('2', rendezvous.find_node('wat'))
  end

  def test_find_node_after_addition
    nodes = ['0', '1', '2']
    rendezvous = RendezvousHash.new(nodes)
    assert_equal('0', rendezvous.find_node('ok'))
    assert_equal('1', rendezvous.find_node('mykey'))
    assert_equal('2', rendezvous.find_node('wat'))
    assert_equal('2', rendezvous.find_node('lol'))
    rendezvous.add_node('3')
    assert_equal('0', rendezvous.find_node('ok'))
    assert_equal('1', rendezvous.find_node('mykey'))
    assert_equal('2', rendezvous.find_node('wat'))
    assert_equal('3', rendezvous.find_node('lol'))
  end

end

class RendezvousHashIntegrationTestCase < Test::Unit::TestCase

  def test_grow
    rendezvous = RendezvousHash.new()

    placements = Hash[]
    for i in (0...10)
      rendezvous.add_node(i.to_s)
      placements[i.to_s] = []
    end
    for i in (0...1000)
      node = rendezvous.find_node(i.to_s)
      placements[node].push(i)
    end

    new_placements = Hash[]
    for i in (0...20)
      rendezvous.add_node(i.to_s)
      new_placements[i.to_s] = []
    end
    for i in (0...1000)
      node = rendezvous.find_node(i.to_s)
      new_placements[node].push(i)
    end

    keys = placements.values.flatten
    new_keys = new_placements.values.flatten
    assert_equal(keys.sort, new_keys.sort)

    added = 0
    removed = 0
    new_placements.each do |node, assignments|
      after = assignments.to_set
      before = placements.fetch(node, []).to_set
      removed += before.difference(after).length
      added += after.difference(before).length
    end

    assert_equal(added, removed)
    assert_equal(1062, (added + removed))
  end

  def test_shrink
    rendezvous = RendezvousHash.new()

    placements = {}
    for i in (0...10)
      rendezvous.add_node(i.to_s)
      placements[i.to_s] = []
    end
    for i in (0...1000)
      node = rendezvous.find_node(i.to_s)
      placements[node].push(i)
    end

    rendezvous.remove_node('9')
    new_placements = {}
    for i in (0...9)
      new_placements[i.to_s] = []
    end
    for i in (0...1000)
      node = rendezvous.find_node(i.to_s)
      new_placements[node].push(i)
    end

    keys = placements.values.flatten
    new_keys = new_placements.values.flatten
    assert_equal(keys.sort, new_keys.sort)

    added = 0
    removed = 0
    placements.each do |node, assignments|
      after = assignments.to_set
      before = new_placements.fetch(node, []).to_set
      removed += before.difference(after).length
      added += after.difference(before).length
    end

    assert_equal(added, removed)
    assert_equal(202, (added + removed))
  end

end
