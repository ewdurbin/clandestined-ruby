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

[![Build Status](https://travis-ci.org/ewdurbin/clandestiny-ruby.svg?branch=master)](https://travis-ci.org/ewdurbin/clandestiny-ruby)

## example usage

```ruby
require 'clandestine/cluster'

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
require 'clandestine/cluster'
require 'clandestine/rendezvous_hash'

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

cluster = Cluster.new(nodes, 1)
rendezvous = RendezvousHash.new(nodes.keys)

puts cluster.find_nodes('mykey')
puts rendezvous.find_node('mykey')
```

outputs
```
4
4
```

## advanced usage

### murmur3 seeding

if you plan to use keys based on untrusted input (not really supported, but go
ahead), it would be best to use a custom seed for hashing. although this
technique is by no means a way to fully mitigate a DoS attack using crafted
keys, it may make you sleep better at night.

```ruby
require 'clandestine/cluster'
require 'clandestine/rendezvous_hash'

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

cluster = Cluster.new(nodes, 1, 1337)
rendezvous = RendezvousHash.new(nodes.keys, 1337)

puts cluster.find_nodes('mykey')
puts rendezvous.find_node('mykey')
```

outputs (note they have changed from above)
```
7
7
```

### supplying your own hash function

a more robust, but possibly slower solution to mitigate DoS vulnerability by
crafted key might be to supply your own cryptograpic hash function.

in order for this to work, your method must be supplied to the `RendezvousHash`
or `Cluster` object as a callable which takes a byte string `key` and returns
an integer.

```ruby
require 'digest'
require 'clandestine/cluster'
require 'clandestine/rendezvous_hash'

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

def my_hash_function(key)
  Digest::SHA1.hexdigest(key).to_i(16)
end

cluster = Cluster.new(nodes, 1, 0, method(:my_hash_function))
rendezvous = RendezvousHash.new(nodes.keys, 0, method(:my_hash_function))

puts cluster.find_nodes('mykey')
puts rendezvous.find_node('mykey')
```

outputs
```
1
1
```
