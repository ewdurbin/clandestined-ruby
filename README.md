clandestiny
===========

rendezvous hashing implementation based on murmur3 hash


## motiviation

in distributed systems, the need often arises to locate objects amongst a
cluster of machines. consistent hashing and rendezvous hashing are methods of
performing this task, while minimizing data movement on cluster topology
changes.

clandestiny is a library for rendezvous hashing which has the goal of simple
clients and ease of use.

Currently targetting for support:
  - Ruby 1.8.6 through Ruby 2.1.x

## characteristics

### cluster distribution
**pretty charts here**

### cluster resizing
**pretty charts here**


## example usage

```ruby
require 'clandestine'

nodes = Hash[
    '1' => Hash['name' => 'node1.example.com', 'zone' => 'us-east-1a'],
    '2' => Hash['name' => 'node2.example.com', 'zone' => 'us-east-1a'],
    '3' => Hash['name' => 'node3.example.com', 'zone' => 'us-east-1a'],
    '4' => Hash['name' => 'node4.example.com', 'zone' => 'us-east-1b'],
    '5' => Hash['name' => 'node5.example.com', 'zone' => 'us-east-1b'],
    '6' => Hash['name' => 'node6.example.com', 'zone' => 'us-east-1b'],
    '7' => Hash['name' => 'node7.example.com', 'zone' => 'us-east-1c'],
    '8' => Hash['name' => 'node8.example.com', 'zone' => 'us-east-1c'],
    '9' => Hash['name' => 'node9.example.com', 'zone' => 'us-east-1c'],
]

cluster = Cluster.new(nodes)
nodes = cluster.find_nodes('mykey')
puts nodes[0]
puts nodes[1]
```

outputs
```
4
8
```

by default, `Cluster` will place 2 replicas around the cluster taking care to
place the second replica in a separate zone from the first.

in the event that your cluster doesn't need zone awareness, you can either
invoke the `RendezvousHash` class directly, or use a `Cluster` with replicas
set to 1

```ruby
require 'clandestine'

nodes = Hash[
    '1' => Hash['name' => 'node1.example.com'],
    '2' => Hash['name' => 'node2.example.com'],
    '3' => Hash['name' => 'node3.example.com'],
    '4' => Hash['name' => 'node4.example.com'],
    '5' => Hash['name' => 'node5.example.com'],
    '6' => Hash['name' => 'node6.example.com'],
    '7' => Hash['name' => 'node7.example.com'],
    '8' => Hash['name' => 'node8.example.com'],
    '9' => Hash['name' => 'node9.example.com'],
]

cluster = Cluster.new(nodes, replicas=1)
rendezvous = RendezvousHash.new(nodes.keys)

puts cluster.find_nodes('mykey')
puts rendezvous.find_node('mykey')
```

outputs
```
4
4
```
