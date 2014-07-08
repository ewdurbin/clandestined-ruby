
require 'test/unit'

require 'clandestined/rendezvous_hash'
require 'clandestined/cluster'

include Clandestined

class CollisionHashTestCase < Test::Unit::TestCase

  def setup
    RendezvousHash.class_eval do
      def mock_murmur3_32(key, seed=0)
        4294967295
      end
      alias original_murmur3_32 murmur3_32
      alias murmur3_32 mock_murmur3_32
    end
  end

  def teardown
    RendezvousHash.class_eval do
      alias murmur3_32 original_murmur3_32
      remove_method(:mock_murmur3_32)
      remove_method(:original_murmur3_32)
    end
  end

  def test_rendezvous_collision
    nodes = ['c', 'b', 'a']
    rendezvous = RendezvousHash.new(nodes)
    assert_equal(rendezvous.hash_function.call('lol'), 4294967295)
    assert_equal(rendezvous.hash_function.call('wat'), 4294967295)
    for i in (0..1000)
      assert_equal('c', rendezvous.find_node(i))
    end
  end

  def test_cluster_collision
    nodes = Hash[
      '1' => Hash['zone' => 'a'],
      '2' => Hash['zone' => 'a'],
      '3' => Hash['zone' => 'b'],
      '4' => Hash['zone' => 'b'],
    ]
    cluster = Cluster.new(nodes)
    for n in (0..100)
      for m in (0..100)
        assert_equal(['2', '4'], cluster.find_nodes_by_index(n, m).sort)
      end
    end
  end

end
