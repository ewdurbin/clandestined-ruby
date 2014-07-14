clandestined
===========

rendezvous hashing implementation based on murmur3 hash


## motivation

in distributed systems, the need often arises to locate objects amongst a
cluster of machines. consistent hashing and rendezvous hashing are methods of
performing this task, while minimizing data movement on cluster topology
changes.

clandestined is a library for rendezvous hashing which has the goal of simple
clients and ease of use.

Currently targetting for support:
  - Ruby 1.8.6 through Ruby 2.1.x

[![Build Status](https://travis-ci.org/ewdurbin/clandestined-ruby.svg?branch=master)](https://travis-ci.org/ewdurbin/clandestined-ruby)

## example usage

```ruby
>> require 'clandestined/cluster'
>>
>> nodes = Hash[
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
>>
>> cluster = Clandestined::Cluster.new(nodes)
>> cluster.find_nodes('mykey')
=> ["4", "8"]
```

by default, `Cluster` will place 2 replicas around the cluster taking care to
place the second replica in a separate zone from the first.

in the event that your cluster doesn't need zone awareness, you can either
invoke the `RendezvousHash` class directly, or use a `Cluster` with replicas
set to 1

```ruby
>> require 'clandestined/cluster'
>> require 'clandestined/rendezvous_hash'
>>
>> nodes = Hash[
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
>>
>> cluster = Clandestined::Cluster.new(nodes, 1)
>> rendezvous = Clandestined::RendezvousHash.new(nodes.keys)
>>
>> cluster.find_nodes('mykey')
=> ["4"]
>> rendezvous.find_node('mykey')
=> "4"
```

## advanced usage

### murmur3 seeding

if you plan to use keys based on untrusted input (supported, but go ahead),
it would be best to use a custom seed for hashing. although this technique is
by no means a way to fully mitigate a DoS attack using crafted keys, it may
help you sleep better at night.

**DISCLAIMER**

clandestined was not designed with consideration for untrusted input, please
see LICENSE.

**END DISCLAIMER**

```ruby
>> require 'clandestined/cluster'
>> require 'clandestined/rendezvous_hash'
>>
>> nodes = Hash[
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
>>
>> cluster = Clandestined::Cluster.new(nodes, 1, 1337)
>> rendezvous = Clandestined::RendezvousHash.new(nodes.keys, 1337)
>>
>> cluster.find_nodes('mykey')
=> ["7"]
>> rendezvous.find_node('mykey')
=> "7"
```
