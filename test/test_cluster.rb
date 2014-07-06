
require 'test/unit'
require 'set'

require 'clandestine'
require 'murmur3'

class ClusterTestCase < Test::Unit::TestCase

    def test_init_no_options
        cluster = Cluster.new()
        assert_equal(1361238019, cluster.hash_function.call('6666'))
        assert_equal(2, cluster.replicas)
        assert_equal(Hash[], cluster.nodes)
        assert_equal([], cluster.zones)
        assert_equal(Hash[], cluster.zone_members)
        assert_equal(Hash[], cluster.rings)
    end

    def test_init_single_zone
        cluster_config = {
            '1' => Hash[],
            '2' => Hash[],
            '3' => Hash[],
        }
        cluster = Cluster.new(cluster_config, 1)
        assert_equal(1, cluster.replicas)
        assert_equal(3, cluster.nodes.length)
        assert_equal(1, cluster.zones.length)
        assert_equal(3, cluster.zone_members[nil].length)
        assert_equal(1, cluster.rings.length)
        assert_equal(3, cluster.rings[nil].nodes.length)
    end

    def test_init_zones
        cluster_config = {
            '1' => {'zone' => 'a'},
            '2' => {'zone' => 'b'},
            '3' => {'zone' => 'a'},
            '4' => {'zone' => 'b'},
            '5' => {'zone' => 'a'},
            '6' => {'zone' => 'b'},
        }
        cluster = Cluster.new(cluster_config)
        assert_equal(2, cluster.replicas)
        assert_equal(6, cluster.nodes.length)
        assert_equal(['a', 'b'], cluster.zones)
        assert_equal(['1', '3', '5'], cluster.zone_members['a'].sort)
        assert_equal(['2', '4', '6'], cluster.zone_members['b'].sort)
        assert_equal(2, cluster.rings.length)
        assert_equal(3, cluster.rings['a'].nodes.length)
        assert_equal(3, cluster.rings['b'].nodes.length)
    end

    def test_add_zone
        cluster = Cluster.new()
        assert_equal(0, cluster.nodes.length)
        assert_equal([], cluster.zones)
        assert_equal(0, cluster.zone_members.length)
        assert_equal(0, cluster.rings.length)

        cluster.add_zone('b')
        assert_equal(0, cluster.nodes.length)
        assert_equal(['b'], cluster.zones)
        assert_equal(0, cluster.zone_members['b'].length)
        assert_equal(0, cluster.rings.length)

        cluster.add_zone('b')
        assert_equal(0, cluster.nodes.length)
        assert_equal(['b'], cluster.zones)
        assert_equal(0, cluster.zone_members['b'].length)
        assert_equal(0, cluster.rings.length)

        cluster.add_zone('a')
        assert_equal(0, cluster.nodes.length)
        assert_equal(['a', 'b'], cluster.zones)
        assert_equal(0, cluster.zone_members['a'].length)
        assert_equal(0, cluster.zone_members['b'].length)
        assert_equal(0, cluster.rings.length)
    end

    def test_add_node
        cluster = Cluster.new()
        assert_equal(0, cluster.nodes.length)
        assert_equal([], cluster.zones)
        assert_equal(0, cluster.zone_members.length)
        assert_equal(0, cluster.rings.length)

        cluster.add_node('2', 'b')
        assert_equal(1, cluster.nodes.length)
        assert_equal(['b'], cluster.zones)
        assert_equal(1, cluster.zone_members.length)
        assert_equal(['2'], cluster.zone_members['b'].sort)
        assert_equal(1, cluster.rings.length)

        cluster.add_node('1', 'a')
        assert_equal(2, cluster.nodes.length)
        assert_equal(['a', 'b'], cluster.zones)
        assert_equal(2, cluster.zone_members.length)
        assert_equal(['1'], cluster.zone_members['a'].sort)
        assert_equal(['2'], cluster.zone_members['b'].sort)
        assert_equal(2, cluster.rings.length)

        cluster.add_node('21', 'b')
        assert_equal(3, cluster.nodes.length)
        assert_equal(['a', 'b'], cluster.zones)
        assert_equal(2, cluster.zone_members.length)
        assert_equal(['1'], cluster.zone_members['a'].sort)
        assert_equal(['2', '21'], cluster.zone_members['b'].sort)
        assert_equal(2, cluster.rings.length)

        assert_raises(ArgumentError) {cluster.add_node('21')}
        assert_raises(ArgumentError) {cluster.add_node('21', nil, nil)}
        assert_raises(ArgumentError) {cluster.add_node('21', 'b', nil)}

        cluster.add_node('22', 'c')
        assert_equal(4, cluster.nodes.length)
        assert_equal(['a', 'b', 'c'], cluster.zones)
        assert_equal(3, cluster.zone_members.length)
        assert_equal(['1'], cluster.zone_members['a'].sort)
        assert_equal(['2', '21'], cluster.zone_members['b'].sort)
        assert_equal(['22'], cluster.zone_members['c'].sort)
        assert_equal(3, cluster.rings.length)
    end

    def test_remove_node
        cluster_config = {
            '1' => {'zone' => 'a'},
            '2' => {'zone' => 'b'},
            '3' => {'zone' => 'a'},
            '4' => {'zone' => 'b'},
            '5' => {'zone' => 'c'},
            '6' => {'zone' => 'c'},
        }
        cluster = Cluster.new(cluster_config)

        cluster.remove_node('4', 'b')
        assert_equal(5, cluster.nodes.length)
        assert_equal(['a', 'b', 'c'], cluster.zones)
        assert_equal(3, cluster.zone_members.length)
        assert_equal(['1', '3'], cluster.zone_members['a'].sort)
        assert_equal(['2'], cluster.zone_members['b'].sort)
        assert_equal(['5', '6'], cluster.zone_members['c'].sort)
        assert_equal(3, cluster.rings.length)

        cluster.remove_node('2', 'b')
        assert_equal(4, cluster.nodes.length)
        assert_equal(['a', 'c'], cluster.zones)
        assert_equal(2, cluster.zone_members.length)
        assert_equal(['1', '3'], cluster.zone_members['a'].sort)
        assert_equal(nil, cluster.zone_members['b'])
        assert_equal(['5', '6'], cluster.zone_members['c'].sort)
        assert_equal(2, cluster.rings.length)
    end

    def test_node_name_by_id
        cluster_config = {
            '1' => {'name' => 'node1', 'zone' => 'a'},
            '2' => {'name' => 'node2', 'zone' => 'b'},
            '3' => {'name' => 'node3', 'zone' => 'a'},
            '4' => {'name' => 'node4', 'zone' => 'b'},
            '5' => {'name' => 'node5', 'zone' => 'c'},
            '6' => {'name' => 'node6', 'zone' => 'c'},
        }
        cluster = Cluster.new(cluster_config)

        assert_equal('node1', cluster.node_name('1'))
        assert_equal('node2', cluster.node_name('2'))
        assert_equal('node3', cluster.node_name('3'))
        assert_equal('node4', cluster.node_name('4'))
        assert_equal('node5', cluster.node_name('5'))
        assert_equal('node6', cluster.node_name('6'))
        assert_equal(nil, cluster.node_name('7'))
    end

    def test_find_nodes
        cluster_config = {
            '1' => {'name' => 'node1', 'zone' => 'a'},
            '2' => {'name' => 'node2', 'zone' => 'a'},
            '3' => {'name' => 'node3', 'zone' => 'b'},
            '4' => {'name' => 'node4', 'zone' => 'b'},
            '5' => {'name' => 'node5', 'zone' => 'c'},
            '6' => {'name' => 'node6', 'zone' => 'c'},
        }
        cluster = Cluster.new(cluster_config)

        assert_equal(['2', '3'], cluster.find_nodes('lol'))
        assert_equal(['6', '2'], cluster.find_nodes('wat'))
        assert_equal(['2', '4'], cluster.find_nodes('ok'))
        assert_equal(['6', '1'], cluster.find_nodes('bar'))
        assert_equal(['1', '3'], cluster.find_nodes('foo'))
        assert_equal(['4', '6'], cluster.find_nodes('slap'))
    end

    def test_find_nodes_by_index
        cluster_config = {
            '1' => {'name' => 'node1', 'zone' => 'a'},
            '2' => {'name' => 'node2', 'zone' => 'a'},
            '3' => {'name' => 'node3', 'zone' => 'b'},
            '4' => {'name' => 'node4', 'zone' => 'b'},
            '5' => {'name' => 'node5', 'zone' => 'c'},
            '6' => {'name' => 'node6', 'zone' => 'c'},
        }
        cluster = Cluster.new(cluster_config)

        assert_equal(['6', '1'], cluster.find_nodes_by_index(1, 1))
        assert_equal(['2', '4'], cluster.find_nodes_by_index(1, 2))
        assert_equal(['4', '5'], cluster.find_nodes_by_index(1, 3))
        assert_equal(['1', '4'], cluster.find_nodes_by_index(2, 1))
        assert_equal(['3', '5'], cluster.find_nodes_by_index(2, 2))
        assert_equal(['5', '2'], cluster.find_nodes_by_index(2, 3))
    end

end


class ClusterIntegrationTestCase < Test::Unit::TestCase

    def test_grow
        cluster_config = {
            '1' => {'name' => 'node1', 'zone' => 'a'},
            '2' => {'name' => 'node2', 'zone' => 'a'},
            '3' => {'name' => 'node3', 'zone' => 'b'},
            '4' => {'name' => 'node4', 'zone' => 'b'},
            '5' => {'name' => 'node5', 'zone' => 'c'},
            '6' => {'name' => 'node6', 'zone' => 'c'},
        }
        cluster = Cluster.new(cluster_config)

        placements = Hash[]
        for i in cluster.nodes.keys
            placements[i] = []
        end
        for i in (0..1000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                placements[node].push(i)
            end
        end

        cluster.add_node('7', 'a', 'node7')
        cluster.add_node('8', 'b', 'node8')
        cluster.add_node('9', 'c', 'node9')

        new_placements = Hash[]
        for i in cluster.nodes.keys
            new_placements[i] = []
        end
        for i in (0..1000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                new_placements[node].push(i)
            end
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
        assert_equal(1340, (added + removed))
    end

    def test_shrink
        cluster_config = {
            '1' => {'name' => 'node1', 'zone' => 'a'},
            '2' => {'name' => 'node2', 'zone' => 'a'},
            '3' => {'name' => 'node3', 'zone' => 'b'},
            '4' => {'name' => 'node4', 'zone' => 'b'},
            '5' => {'name' => 'node5', 'zone' => 'c'},
            '6' => {'name' => 'node6', 'zone' => 'c'},
            '7' => {'name' => 'node7', 'zone' => 'a'},
            '8' => {'name' => 'node8', 'zone' => 'a'},
            '9' => {'name' => 'node9', 'zone' => 'b'},
            '10' => {'name' => 'node10', 'zone' => 'b'},
            '11' => {'name' => 'node11', 'zone' => 'c'},
            '12' => {'name' => 'node12', 'zone' => 'c'},
        }
        cluster = Cluster.new(cluster_config)

        placements = Hash[]
        for i in cluster.nodes.keys
            placements[i] = []
        end
        for i in (0...10000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                placements[node].push(i)
            end
        end

        cluster.remove_node('7', 'a', 'nodee7')
        cluster.remove_node('9', 'b', 'node9')
        cluster.remove_node('11', 'c', 'node11')

        new_placements = Hash[]
        for i in cluster.nodes.keys
            new_placements[i] = []
        end
        for i in (0...10000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                new_placements[node].push(i)
            end
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
        assert_equal(9892, (added + removed))
    end

    def test_add_zone
        cluster_config = {
            '1' => {'name' => 'node1', 'zone' => 'a'},
            '2' => {'name' => 'node2', 'zone' => 'a'},
            '3' => {'name' => 'node3', 'zone' => 'b'},
            '4' => {'name' => 'node4', 'zone' => 'b'},
        }
        cluster = Cluster.new(cluster_config)

        placements = Hash[]
        for i in cluster.nodes.keys
            placements[i] = []
        end
        for i in (0...1000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                placements[node].push(i)
            end
        end

        cluster.add_node('5', 'c', 'node5')
        cluster.add_node('6', 'c', 'node6')

        new_placements = Hash[]
        for i in cluster.nodes.keys
            new_placements[i] = []
        end
        for i in (0...1000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                new_placements[node].push(i)
            end
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
        assert_equal(1332, (added + removed))
    end

    def test_remove_zone
        cluster_config = {
            '1' => {'name' => 'node1', 'zone' => 'a'},
            '2' => {'name' => 'node2', 'zone' => 'a'},
            '3' => {'name' => 'node3', 'zone' => 'b'},
            '4' => {'name' => 'node4', 'zone' => 'b'},
            '5' => {'name' => 'node5', 'zone' => 'c'},
            '6' => {'name' => 'node6', 'zone' => 'c'},
            '7' => {'name' => 'node7', 'zone' => 'a'},
            '8' => {'name' => 'node8', 'zone' => 'a'},
            '9' => {'name' => 'node9', 'zone' => 'b'},
            '10' => {'name' => 'node10', 'zone' => 'b'},
            '11' => {'name' => 'node11', 'zone' => 'c'},
            '12' => {'name' => 'node12', 'zone' => 'c'},
        }
        cluster = Cluster.new(cluster_config)

        placements = Hash[]
        for i in cluster.nodes.keys
            placements[i] = []
        end
        for i in (0...10000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                placements[node].push(i)
            end
        end

        cluster.remove_node('5', 'c', 'node5')
        cluster.remove_node('6', 'c', 'node6')
        cluster.remove_node('11', 'c', 'node11')
        cluster.remove_node('12', 'c', 'node12')

        new_placements = Hash[]
        for i in cluster.nodes.keys
            new_placements[i] = []
        end
        for i in (0...10000)
            nodes = cluster.find_nodes(i.to_s)
            for node in nodes
                new_placements[node].push(i)
            end
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
        assert_equal(13332, (added + removed))
    end

end
