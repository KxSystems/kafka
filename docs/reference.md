# ![Apache Kafka](kafka.png) Kafka function reference 


The kdb+/Kafka interface is a thin wrapper for kdb+ around the [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Apache Kafka](https://kafka.apache.org/). 



## **`.kfk.`** Kafka interface 

System information<br>
[`Metadata`](#metadata) Broker Metadata<br>
[`Version`](#version) Librdkafka version<br>
[`VersionSym`](#versionsym) Human readable Librdkafka version<br>
[`ThreadCount`](#threadcount) Number of threads being used by librdkafka

Topics<br>
[`Topic`](#topic) Create a topic on which messages can be sent<br>
[`TopicDel`](#topicdel) Delete a defined topic<br>
[`TopicName`](#topicname) Topic Name

Callback modifications<br>
[`errcbreg`](#errcbreg) Register an error callback associated with a specific client<br>
[`throttlecbreg`](#throttlecbreg) Register a throttle callback associated with a specific client

Clients<br>
[`ClientDel`](#clientdel) Close consumer and destroy Kafka handle to client<br>
[`ClientName`](#clientname) Kafka handle name<br>
[`ClientMemberId`](#clientmemberid) Client's broker assigned member ID<br>
[`Consumer`](#consumer) Create a consumer according to defined configuration<br>
[`Producer`](#producer) Create a producer according to defined configuration<br>
[`SetLoggerLevel`](#setloggerlevel) Set the maximum logging level for a client

Offsets<br>
[`CommitOffsets`](#commitoffsets) Commit offsets on broker for provided partition list<br>
[`PositionOffsets`](#positionoffsets) Current offsets for topics and partitions<br>
[`CommittedOffsets`](#committedoffsets) Retrieve committed offsets for topics and partitions<br>
[`queryWatermark`](#querywatermark) Query broker for low (oldest/beginning) and high (newest/end) offsets for partition.

Publishing <br>
[`BatchPub`](#batchpub) Publish a batch of data to a defined topic<br>
[`Pub`](#pub) Publish a message to a defined topic<br>
[`PubWithHeaders`](#pubwithheaders) Publish a message to a defined topic with a header <br>
[`OutQLen`](#outqlen) Current out queue length

[Subscriptions](#subscriptions)<br>

[Dynamic](#dynamic) assigned subscriptions<br>
[`Sub`](#sub) Subscribe to a defined topic<br>
[`Subscribe`](#subscribe) Subscribe from a consumer to a topic with a specified callback<br>
[`Subscription`](#subscription) Most recent topic subscription<br>

[Manual](#manual) assigned partitions/offsets<br>
[`Assign`](#assign) Create a new assignment from which data will be consumed<br>
[`AssignOffsets`](#assignoffsets) Assignment of partitions to consume<br>
[`AssignAdd`](#assignadd) Add new assignments to the current assignment<br>
[`AssignDel`](#assigndel) Remove topic partition assignments from the current assignments<br>
[`Assignment`](#assignment) Return the current assignment<br>

[Common](#common)<br>
[`consumetopic`](#consumetopic) Called for each message received<br>
[`Unsub`](#unsub) Unsubscribe from a topic<br>
[`MaxMsgsPerPoll`](#maxmsgsperpoll) Set the maximum number of messages per poll<br>
[`Poll`](#poll) Manually poll the feed

## System information

### `Metadata`

_Information about configuration of brokers and topics_

```txt
.kfk.Metadata id
```

Where `id` is a consumer or producer ID, returns a dictionary populated with the following info:

-   `orig_broker_id` (int): Broker originating this metadata
-   `orig_broker_name` (symbol): Name of originating broker
-   `brokers` (list of dictionaries): Info on current brokers
-   `topics` (list of dictionaries): Info on current topics

e.g.

```q
q)show producer_meta:.kfk.Metadata producer
orig_broker_id  | 0i
orig_broker_name| `localhost:9092/0
brokers         | ,`id`host`port!(0i;`localhost;9092i)
topics          | (`topic`err`partitions!(`test3;`Success;,`id`err`leader`rep..
q)producer_meta`topics
topic              err     partitions                                        ..
-----------------------------------------------------------------------------..
test               Success ,`id`err`leader`replicas`isrs!(0i;`Success;0i;,0i;..
__consumer_offsets Success (`id`err`leader`replicas`isrs!(0i;`Success;0i;,0i;..
```

### `ThreadCount`

_The number of threads in use by librdkafka_

```txt
.kfk.ThreadCount[]
```

returns the number of threads currently in use by `librdkafka`.

```q
q).kfk.ThreadCount[]
5i
```

### `Version`

_Version of librdkafka (integer)_

```txt
.kfk.Version[]
```

Returns the `librdkafka` version (integer) used within the interface.

```q
q).kfk.Version
16777471i
```

### `VersionSym`

_Version of librdkafka (symbol)_

```txt
.kfk.VersionSym[]
```

Returns the `librdkafka` version (symbol) used within the interface.

```q
q).kfk.VersionSym[]
`1.1.0
```

## Topics

### `Topic`

_Create a topic on which messages can be sent_

```txt
.kfk.Topic[id;topic;cfg]
```

Where

-   `id` is a consumer or producer ID
-   `topic` is a name to be assigned to the topic (symbol)
-   `cfg` is a user-defined topic configuration (dictionary): default: `()!()`

returns the topic ID (integer).

```q
q)consumer:.kfk.Consumer[kfk_cfg]
q).kfk.Topic[consumer;`test;()!()]
0i
q).kfk.Topic[consumerl`test1;()!()]
1i
```

### `TopicDel`

_Delete a currently defined topic_

```txt
.kfk.TopicDel topic
```

Where `topic` is a topic ID, deletes the topic and returns a null.

```q
q).kfk.Topic[0i;`test;()!()]
0i
q).kfk.TopicDel[0i]
q)/ topic now no longer available for deletion
q).kfk.TopicDel[0i]
'unknown topic
```


### `TopicName`

_Returns the name of a topic_

```txt
.kfk.TopicName tpcid
```

Where `tpcid` is a topic ID, returns its name  as a symbol.

```q
q).kfk.Topic[0i;`test;()!()]
0i
q).kfk.Topic[0i;`test1;()!()]
1i
q).kfk.TopicName[0i]
`test
q).kfk.TopicName[1i]
`test1
```

## Callback Modifications

### `errcbreg`

_Register an error callback associated with a specific client_

```txt
.kfk.errcbreg[clid;callback]
```

Where

-   `clid` is a client ID (integer)
-   `callback` is a ternary function

sets `callback` to be triggered by errors associated with the client, 
augments the dictionary `.kfk.errclient` mapping client ID to callback,
and returns a null.

The arguments of `callback` are:

-   `cid`: ID of client for which this is called (integer)
-   `err_int`: error status code in Kafka (integer)
-   `reason`: error message (string)


```q
q)// Assignment prior to registration of new callback
q)// this is the default behavior invoked
q).kfk.errclient
 |{[cid;err_int;reason]}
q)// Attempt to create a consumer which will fail
q).kfk.Consumer[`metadata.broker.list`group.id!`foobar`0]
0i

q)// Update the default behavior to show the output
q).kfk.errclient[`]:{[cid;err_int;reason]show(cid;err_int;reason);}

q)// Attempt to create another failing consumer
q).kfk.Consumer[`metadata.broker.list`group.id!`foobar`0]
1i
q)1i
-193i
"foobar:9092/bootstrap: Failed to resolve 'foobar:9092': nodename nor servnam..
1i
-187i
"1/1 brokers are down"

q)// Start a new q session and register an error callback for cid 0
q).kfk.errcbreg[0i;{[cid;err_int;reason] show err_int;}]
q)// Attempt to create a consumer that will fail
q).kfk.Consumer[`metadata.broker.list`group.id!`foobar`0]
0i
q)-193i
-187i
```

### `throttlecbreg`

_Register an throttle callback associated with a specific client_

```txt
.kfk.throttlecbreg[clid;callback]
```

Where

-   `clid` is a client ID (integer)
-   `callback` is a quaternary function

sets `callback` to be triggered on throttling associated with the client, 
augments the dictionary `.kfk.errclient` mapping client ID to callback,
and returns a null.

The arguments of `callback` are:

-   `cid`: ID (integer) of client for which this is called 
-   `bname`: broker name (string)
-   `bid`: broker ID (integer)
-   `throttle_time`: accepted throttle time in milliseconds (integer)

```q
q)// Assignment prior to registration of new callback 
q)// this is the default behavior invoked
q).kfk.throttleclient
 |{[cid;bname;bid;throttle_time]}

q)// Update the default behavior to show the output
q).kfk.throttleclient[`]:{[cid;bname;bid;throttle_time]show(cid;bid);}

q)// Add a throttle client associated specifically with client 0
q).kfk.throttlecbreg[0i;{[cid;bname;bid;throttle_time]show(cid;throttle_time);}]

q)// Display the updated throttle callback logic
q).kfk.throttleclient
 |{[cid;bname;bid;throttle_time]show(cid;bid);}
0|{[cid;bname;bid;throttle_time]show(cid;throttle_time);}
```

## Clients

The following functions relate to the creation of consumers and producers and their manipulation/interrogation.

### `ClientDel`

_Close a consumer and destroy the associated Kafka handle to client_

```txt
.kfk.ClientDel clid
```

Where  `clid` is the client to be deleted (integer), returns null on successful deletion. 
If client unknown, signals `'unknown client`.

```q
/Client exists
q).kfk.ClientName 0i
`rdkafka#consumer-1
q).kfk.ClientDel 0i
q).kfk.ClientName 0i
'unknown client
/Client can no longer be deleted
q).kfk.ClientDel 0i
'unknown client
```

### `ClientMemberId`

_Client's broker-assigned member ID_

```txt
.kfk.ClientMemberId clid
```

Where `clid` is a client ID (integer), returns the member ID (symbol) assigned to the client, or signals `unknown client`.

> :warning: **Consumer processes only**
> 
> This function should be called only on a consumer process. 
> This is an [external limitation](https://docs.confluent.io/2.0.0/clients/librdkafka/rdkafka_8h.html#a856d7ecba1aa64e5c89ac92b445cdda6).

```q
q).kfk.ClientMemberId 0i
`rdkafka-881f3ee6-369b-488a-b6b2-c404d45ebc7c
q).kfk.ClientMemberId 1i
'unknown client
```

### `ClientName`

_Kafka handle name_

```txt
.kfk.ClientName clid
```

Where `clid` is a client ID (integer), returns assigned client name (symbol) or signals `unknown client`.

```q
q).kfk.ClientName 0i
`rdkafka#producer-1
/Client removed
q).kfk.ClientName 1i
'unknown client
```

### `Consumer`

_Create a consumer according to user-defined configuration_

```txt
.kfk.Consumer cfg
```

Where `cfg` is a dictionary user-defined configuration, returns the ID of the consumer as an integer.

```q
q)kfk_cfg
metadata.broker.list  | localhost:9092
group.id              | 0
queue.buffering.max.ms| 1
fetch.wait.max.ms     | 10
statistics.interval.ms| 10000
q).kfk.Consumer kfk_cfg
0i
```

:point_right: 
[edenhill/librdkafka/CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md) for a list of cfg options

### `Producer`

_Create a producer according to user-defined configuration_

```txt
.kfk.Producer cfg
```

Where `cfg` is a user-defined dictionary configuration, returns the ID of the producer as an integer.

```q
q)kfk_cfg
metadata.broker.list  | localhost:9092
statistics.interval.ms| 10000
queue.buffering.max.ms| 1
fetch.wait.max.ms     | 10
q).kfk.Producer kfk_cfg
0i
```

:point_right: 
[edenhill/librdkafka/CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md) for a list of cfg options

### `SetLoggerLevel`

_Set the maximum logging level for a client_

```txt
.kfk.SetLoggerLevel[clid;level]
```

Where

-   `clid` is the client ID (int)
-   `level` is the syslog severity level (int/long/short)

returns a null on successful application of function.

```q
q)show client
0i
q).kfk.SetLoggerLevel[client;7]
```

## Offset functionality

The following functions relate to use of offsets within the API to ensure records are read correctly from the broker.

!!! note "Multiple topic offset assignment"

    As of v1.4.0 offset functionality can now handle calls associated with multiple topics without overwriting previous definitions. To apply the functionality this must be called for each topic.

### `CommitOffsets`

_Commit offsets on broker for provided partitions and offsets_

```txt
.kfk.CommitOffsets[clid;topic;part_offsets;block_commit]
```

Where

-   `clid` is a consumer client ID (int)
-   `topic` is a topic (symbol)
-   `part_offsets` is a dictionary of partitions(ints) and last received offsets (longs)
-   `block_commit` is whether commit will block until offset commit is complete (boolean)

returns a null on successful commit of offsets.

### `PositionOffsets`

_Current offsets for particular topics and partitions_

```txt
.kfk.PositionOffsets[clid;topic;part_offsets]
```

Where

-   `clid` is the consumer ID (int)
-   `topic` is the topic (symbol)
-   `part_offsets` is a list of partitions (int, short, or long), or a dictionary of partitions (int) and offsets (long)

returns a table containing the current offset and partition for the topic of interest.

```q
q)client:.kfk.Consumer kfk_cfg
q)TOPIC:`test
q)show seen:exec last offset by partition from data
0|0
// dictionary input
q).kfk.PositionOffsets[client;TOPIC;seen]
topic partition offset metadata
-------------------------------
test  0         26482  ""
// int list input
q).kfk.PositionOffsets[client;TOPIC;0 1i]
topic partition offset metadata
-------------------------------
test  0         26482  ""
test  1         -1001  ""
// long list input
q).kfk.PositionOffsets[client;TOPIC;0 1 2]
topic partition offset metadata
-------------------------------
test  0         26482  ""
test  1         -1001  ""
test  2         -1001  ""
```

### `CommittedOffsets`

_Retrieve the last-committed offset for a topic on a particular partition_

```txt
.kfk.CommittedOffsets[clid;topic;part_offsets]
```

Where

-   `clid` is a consumer ID (integer)
-   `topic` is a topic (symbol)
-   `part_offsets` is a list of partitions (int, short, or long), or a dictionary of partitions (int) and offsets (long)

returns a table containing the offset for a particular partition for a topic.

```q
q)client:.kfk.Consumer[kfk_cfg];
q)TOPIC:`test
q)show seen:exec last offset by partition from data;
0|0
// dictionary input
q).kfk.CommittedOffsets[client;TOPIC;seen]
topic partition offset metadata
-------------------------------
test  0         26481  ""
// integer list input
q).kfk.CommittedOffsets[client;TOPIC;0 1i]
topic partition offset metadata
-------------------------------
test  0         26481  ""
test  1         -1001  ""
// long list input
q).kfk.CommittedOffsets[client;TOPIC;0 1]
topic partition offset metadata
-------------------------------
test  0         26481  ""
test  1         -1001  ""
```


### `queryWatermark`

_Query broker for low (oldest/beginning) and high (newest/end) offsets for partition_

```txt
.kfk.queryWatermark[client;`test1;0;1000]
```

Where

-   `clid` is a consumer ID (integer)
-   `topic` is a topic (symbol)
-   `partition` partition (long)
-   `timeout` timeout in ms (long)

returns 2 element long for low/high watermark

## Publishing functionality

### `BatchPub`

_Publish a batch of messages to a defined topic_

```txt
.kfk.BatchPub[tpcid;partid;data;keys]
```

Where

-   `tpcid` is the topic (previously created) to be published on (integer)
-   `partid` is the target partition/s (integer atom or list)
-   `data` is a mixed list payload containing either bytes or strings
-   `keys` is an empty string for auto key on all messages or a key per message as a mixed list of bytes or strings

returns an integer list denoting the status for each message (zero indicating success)

```q
q)batchMsg :("test message 1";"test message 2")
q)batchKeys:("Key 1";"Key 2")

q)// Send two messages to any partition using default key
q).kfk.BatchPub[;.kfk.PARTITION_UA;batchMsg;""]each(topic1;topic2)
0 0
0 0

q)// Send 2 messages to partition 0 for each topic using default key
q).kfk.BatchPub[;0i;batchMsg;""]each(topic1;topic2)
0 0
0 0

q)// Send 2 messages the first to separate partitions using generated keys
q).kfk.BatchPub[;0 1i;batchMsg;batchKeys]each(topic1;topic2)
0 0
0 0
```

### `Pub`

_Publish a message to a defined topic_

```txt
.kfk.Pub[tpcid;partid;data;keys]
```

Where

-   `tpcid` is the topic to be published on (integer)
-   `partid` is the target partition (integer)
-   `data` is the payload to be published (string)
-   `keys` is the message key (string) to be passed with the message to the partition 

returns a null on successful publication.

```q
q)producer:.kfk.Producer kfk_cfg
q)test_topic:.kfk.Topic[producer;`test;()!()]
/ partition set as -1i denotes an unassigned partition
q).kfk.Pub[test_topic;-1i;string .z.p;""]
q).kfk.Pub[test_topic;-1i;string .z.p;"test_key"]
```

### `PubWithHeaders`

_Publish a message to a defined topic, with an associated header_

```txt
.kfk.PubWithHeader[clid;tpcid;partid;data;keys;hdrs]
```

Where

-   `clid` is a target client ID (integer)
-   `tpcid` is the topic to be published on (integer)
-   `partid` is the target partition (integer)
-   `data` is the payload to be published (string)
-   `keys` is the message key (string) to be passed with the message to the partition 
-   `hdrs` is a dictionary mapping a header name (symbol) to a byte array or string

returns a null on successful publication; errors if version conditions not met.

```q
// Create an appropriate producer
producer:.kfk.Producer kfk_cfg

// Create a topic
test_topic:.kfk.Topic[producer;`test;()!()]

// Define the target partition as unassigned
part:-1i

// Define an appropriate payload
payload:string .z.p

// Define the headers to be added
hdrs:`header1`header2!("test1";"test2")

// Publish a message to client #0 with a header but no key
.kfk.PubWithHeaders[0i;test_topic;part;payload;"";hdrs]

// Publish a message to client #1 with headers and a key
.kfk.PubWithHeaders[1i;test_topic;part;payload;"test_key";hdrs]
```

> **Support for functionality**
>     
> This functionality is only available for versions of `librdkafka` ≥ 0.11.4; use of a version less than this does not allow this 

### `OutQLen`

_Current number of messages that are queued for publishing_

```txt
.kfk.OutQLen prid
```

Where `prid` is the integer value of the producer which we wish to check the number of queued messages, returns as an int the number of messages in the queue.

```q
q).kfk.OutQLen producer
5i
```

## Subscriptions


!!! warning "Mixing Manual and Dynamic Assignments"

    It isn't possible to mix manual partition assignment (i.e. using assign) with dynamic partition assignment through topic subscription


### Dynamic

Used when subscribing to the topics we were interested in and let Kafka dynamically assign a fair share of the partitions for those topics based on the active consumers in the group.

Membership in a consumer group is maintained dynamically: if a process fails, the partitions assigned to it will be reassigned to other consumers in the same group.

The subscribe method is not incremental: you must include the full list of topics that you want to consume from.

!!! note "Rebalance"

    A rebalance operation occurs if any one of the following events are triggered:

    -   Number of partitions change for any of the subscribed topics
    -   A subscribed topic is created or deleted
    -   An existing member of the consumer group is shutdown or fails
    -   A new member is added to the consumer group

     Group rebalances will cause partition offsets to be reset (e.g. application of auto.offset.reset setting) 

#### `Sub`

_High level subscription from a consumer process to a topic_

```txt
.kfk.Sub[clid;topic;partid]
```

Where

-   `clid` is the client ID (integer)
-   `topic` is the topic/s being subscribed to (symbol atom – or list, for v1.6+)
-   `partid` is the target partition (enlisted integer) (UNUSED)

returns a null on successful execution.

**Subscribing in advance**
Subscriptions can be made to topics that do not currently exist.

**Multiple subscriptions** 
As of v1.4.0 multiple calls to `.kfk.Sub` for a given client will allow for consumption from multiple topics rather than overwriting the subscribed topic, although each addition will cause a rebalance.

> :warning: **Partition ID**
> 
> The parameter `partid` is a legacy argument to the function and with recent versions of librdkafka does not have any effect on the subscription. On subscription Kafka handles organisation of consumers based on the active members of a `group.id` to efficiently distribute consumption amongst the group.

```q
q)client:.kfk.Consumer[kfk_cfg]
q).kfk.PARTITION_UA // subscription defined to be to an unassigned partition
-1i
// List of topics to be subscribed to
q).kfk.Sub[client;(topic1;topic2);enlist .kfk.PARTITION_UA]
```

#### `Subscribe`

_Subscribe from a consumer to a topic with a specified callback_

```txt
.kfk.Subscribe[clid;topic;partid;callback]
```

Where

-   `clid` is the client ID (integer)
-   `topic` is the topic/s being subscribed to (symbol atom – or list, for v1.6+)
-   `partid` is the target partition (enlisted integer) (UNUSED)
-   `callback` is a callback function defined related to the subscribed topic. This function should take as input a single parameter, 
    the content of a message received from any calls to the subscription on the topic.

returns a null on successful execution and augments `.kfk.consumetopic` with a new callback function for the consumer.

> :warning: **Partition ID**
> 
> The parameter `partid` is a legacy argument to the function and with recent versions of librdkafka does not have any effect on the subscription. On subscription Kafka handles organization of consumers based on the active members of a `group.id` to efficiently distribute consumption among the group.

```q
q)// create a client with a user created config kfk_cfg
q)client:.kfk.Consumer kfk_cfg
q)// Subscription consumes from any available partition
q)part:.kfk.PARTITION_UA 
q)// List of topics to be subscribed to
q)topicname:`test
q)// Display consumer callbacks prior to new subscription
q).kfk.consumetopic
     | {[msg]}
q).kfk.Subscribe[client;topicname;enlist part;{[msg]show msg;}]
q)// Display consumer callbacks following invocation of Subscribe
q).kfk.consumetopic
    | {[msg]}
test| {[msg]show msg;}
```

> **Consume callbacks**
>     
> The addition of callbacks specific to a topic was added in `v1.5.0` a call of `.kfk.Subscribe` augments the dictionary `.kfk.consumetopic` where the key maps topic name to the callback function in question. A check for a custom callback is made on each call to `.kfk.consumecb` following `v1.5.0`. If an appropriate key is found the associated callback will be invoked. The default callback can be modified via modification of ```.kfk.consumetopic[`]```

#### `Subscription`

_Most-recent subscription to a topic_

```txt
.kfk.Subscription clid
```

Where `clid` is the client ID (integer) which the subscription is being requested for, 
returns a table with the topic, partition, offset and metadata of the most recent subscription.

```q
q)client:.kfk.Consumer kfk_cfg
q).kfk.Sub[client;`test2;enlist -1i]
q).kfk.Subscription client
topic partition offset metadata
-------------------------------
test2 -1        -1001  ""
```

### Manual

Permits the user to be in full control of consumption of messages from their choosen topic partition and offset.

Dynamic partition assignment and consumer group coordination will be disabled on use.

The assign methods are not incremental: you must include the full list of topics that you want to consume from.

Manual partition assignment does not use group coordination, so consumer failures will not cause assigned partitions to be rebalanced. Each consumer acts independently even if it shares a groupId with another consumer. To avoid offset commit conflicts, you should usually ensure that the groupId is unique for each consumer instance.

#### `Assign`

_Create a new assignment from which to consume data; remove previous assignments._

```txt
.kfk.Assign[clid;tpc_part]
```

Where

-   `clid` is an integer denoting the client ID which the assignment is to applied
-   `tpc_part` is a dictionary mapping topic names (symbol) to partitions (long), or from v.1.6 onwards a Symbol!Dictionary mapping of topic to partitions/offset (dictionary mapping of integer partition to long offset location)


returns a null on successful execution.

```q
// subscribe to test (partition 0) and test1 (partition 1)
.kfk.Assign[cid;`test`test1!0 1]

// subscribe to test1 (partition 0 from offset 10) and test2 
// (partition 0 from offset 10)
.kfk.Assign[client;`test1`test2!(((1#0i)!1#10);((1#0i)!1#10))]
```

#### `AssignOffsets`

_Assign partitions to be consumed._

```txt
.kfk.AssignOffsets[clid;topic;part_offsets]
```

Where

-   `clid` is the consumer ID (integer)
-   `topic` is the topic (symbol)
-   `part_offsets` is a dictionary of partitions and where to start consuming them

returns a null on successful execution.

If previous assignments for a different topic/partition have already been communicated to the Kafka infrastructure, these assignments will be reapplied.

> From v1.6, [`.kfk.Assign`](#assign) is preferred for assigning multiple offsets/topics.

```q
q).kfk.OFFSET.END   // start consumption at end of partition
-1
q).kfk.OFFSET.BEGINNING // start consumption at start of partition
-2
q).kfk.AssignOffsets[client;TOPIC;(1#0i)!1#.kfk.OFFSET.END]
```

> **Last-committed offset**
> 
> In the above examples an offset of -1001 is a special value. 
> It indicates the offset could not be determined and the consumer will read from the last-committed offset once one becomes available.

#### `AssignAdd`

_Add additional topic-partition pairs to the current assignment._

```txt
.kfk.Assign[clid;tpc_part]
```

Where

-   `clid` is the client ID (integer)
-   `tpc_part` is a dictionary mapping topic names (symbol) to partitions (long), to be added to the current assignment

returns a null on successful execution; will display inappropriate assignments if necessary

> From v1.6, [`.kfk.Assign`](#assign) is preferred for assigning multiple offsets/topics.

If previous assignments have already been communicated to the Kafka infrastructure, these assignments will be reapplied.

```q
q)// Create a new assignment
q).kfk.Assign[cid;`test`test1!0 0]

q)// Retrieve the current assignment
q).kfk.Assignment[cid]
topic partition offset metadata
-------------------------------
test1 0         -1001  ""      
test2 0         -1001  ""      

q)// Add new assignments to the current assignment
q).kfk.AssignAdd[cid;`test`test1!1 1]

q)// Retrieve the current assignment
q).kfk.Assignment[cid]
topic partition offset metadata
-------------------------------
test  1         -1001  ""      
test1 0         -1001  ""      
test1 1         -1001  ""      
test2 0         -1001  ""      

q)// Attempt to assign an already assigned topic partition pair
q).kfk.AssignAdd[cid;`test`test1!1 1]
`test  1
`test1 1
'The above topic-partition pairs already exist, please modify dictionary
```

#### `AssignDel`

_Delete a set of topic-partition pairs from the current assignment._

```txt
.kfk.AssignDel[clid;tpc_part]
```

Where

-   `clid` is a client ID (integer) 
-   `tpc_part` is a dictionary mapping topic names (symbol) to partitions (long)

removes the topic-partition pairs and returns a null; will display inappropriate assignment deletion if necessary.

> From v1.6, [`.kfk.Assign`](#assign) is preferred for assigning multiple offsets/topics.

If previous assignments have already been communicated to the Kafka infrastructure, these remaining assignments will be reapplied

```q
q)// Create a new assignment
q).kfk.Assign[cid;`test`test`test1`test1!0 1 0 1]

q)// Retrieve the current assignment
q).kfk.Assignment[cid]
topic partition offset metadata
-------------------------------
test  0         -1001  ""
test  1         -1001  ""
test1 0         -1001  ""
test1 1         -1001  ""

q)// Add new assignments to the current assignment
q).kfk.AssignDel[cid;`test`test1!1 1]

q)// Retrieve the current assignment
q).kfk.Assignment[cid]
topic partition offset metadata
-------------------------------
test  0         -1001  ""
test1 0         -1001  ""

q)// Attempt to assign an already unassigned topic partition pair
q).kfk.AssignDel[cid;`test`test1!1 1]
`test  1
`test1 1
'The above topic-partition pairs cannot be deleted as they are not assigned
```

#### `Assignment`

_Retrieve the current assignment for a specified client_

```txt
.kfk.Assignment clid
```

Where `clid` is a client ID, returns a list of dictionaries describing the current assignment for it.

```q
q)// Attempt to retrieve assignment without a current assignment
q).kfk.Assignment cid 
topic partition offset metadata
-------------------------------

q)// Create a new assignment
q).kfk.Assign[cid;`test`test1!0 1]

q)// Retrieve the new current assignment
q).kfk.Assignment[cid]
topic partition offset metadata
-------------------------------
test  0         -1001  ""
test1 1         -1001  ""
```

### Common

#### `consumetopic`

_Main unary function called on consumption of data for both default and per topic callback. Called for each message received._

```txt
.kfk.consumetopic msg
```
Where `msg` is the content of a message received from any calls to the subscription on the topic.

#### `Unsub`

_Unsubscribe from all topics associated with Client regardless of whether created via manual or dynamic assigned subscriptions_

```txt
.kfk.Unsub clid
```

Where `clid` is a client ID (integer), unsubscribes it from all topics and returns a null; signals an error if client is unknown.

```q
q).kfk.Unsub[0i]
q).kfk.Unsub[1i]
'unknown client
```

#### `MaxMsgsPerPoll`

_Set the maximum number of messages per poll_

```txt
.kfk.MaxMsgsPerPoll max_messages
```

Where `max_messages` is the maximum number of messages (integer) per poll returns the set limit.

```q
q).kfk.MaxMsgsPerPoll 100
100
```

> **Upper limit set by `.kfk.MaxMsgsPerPoll` vs max_messages in `.kfk.Poll`**
> 
> The argument `max_messages` passed to `.kfk.Poll` is preferred to the global limit of maximum number of messages set by `.kfk.MaxMsgPerPoll`. 
> The latter limit is used only when `max_messages` passed to `.kfk.Poll` is 0.

#### `Poll`

_Manually poll the messages from the message feed_

```txt
.kfk.Poll[cid;timeout;max_messages]
```

Where

-   `cid` is a client ID (integer)
-   `timeout` is max time in ms to block the process (long)
-   `max_messages` is the max number of messages to be polled (long)

returns the number of messages polled within the allotted time.

```q
q).kfk.Poll[0i;5;100]
0
q).kfk.Poll[0i;100;100]
10
```


