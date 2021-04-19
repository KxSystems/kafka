---
title: Guide for using Kafka with kdb+
description: Lists functions available for use within the Kafka API for kdb+ and gives limitations as well as examples of each being used 
date: March 2021
keywords: broker, consumer, kafka, producer, publish, subscribe, subscription, topic
---
# Function reference 

As outlined in the overview for this API, the kdb+/Kafka interface is a thin wrapper for kdb+ around the [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Apache Kafka](https://kafka.apache.org/). 

[KxSystems/kafka](https://github.com/KxSystems/kafka)

The following functions are those exposed within the `.kafka` namespace allowing users to interact with Kafka from a kdb+ instance.

```txt
Kafka interface functionality

  // client functionality 
  .kafka.deleteClient                             Close consumer and destroy Kafka handle to client. All registered callback for this client are removed.
  .kafka.getClientName                            Get a name of client from client index.
  .kafka.getOutQueueLength                        Current out queue length.
  .kafka.newConsumer                              Create a consumer according to defined configuration.
  .kafka.newProducer                              Create a producer according to defined configuration.
  .kafka.setLogLevel                              Set the maximum logging level for a client.

  // Producer functionality
  .kafka.flushProducerHandle                      Flush a handle of a producer.
  .kafka.publish                                  Publish a message to a defined topic.
  .kafka.publishBatch                             Publish a batch of data to a defined topic.
  .kafka.publishWithHeaders                       Publish a message to a defined topic with a header.

  // Consumer functionality
  .kafka.getConsumerGroupMemberID                 Get a broker-assigned member ID.
  .kafka.getCurrentSubscription                   Get current topic subscription information for the consumer.
  .kafka.subscribe              Subscribe to a defined topic.
  .kafka.unsubscribe                              Unsubscribe from a topic and remove consume-topic callback.

  // Callback registration
  .kafka.registerErrorCallback                    Register an error callback associated with a specific client.
  .kafka.registerThrottleCallback                 Register a throttle callback associated with a specific client.
  .kafka.registerConsumeTopicCallback             Register a topic consumption callback associated with a specific client-topic pair.
  .kafka.log_cb                                   User custom callback for log message.
  .kafka.offset_commit_cb                         User custom callback for offset commit.
  .kafka.dr_msg_cb                                User custom callback for message delivery notification.

  // Topic functionality
  .kafka.deleteTopic                              Delete a defined topic.
  .kafka.getTopicName                             Get a topic namefrom a topic index.
  .kafka.newTopic                                 Create a new topic on which messages can be sent.

  // Offsets/Topic-partition functionality
  .kafka.addTopicPartitionToAssignment            Add pairs of topic and partition to the current assignment for a client.
  .kafka.assignNewOffsetsToTopicPartition         Set offsets on partitions of a given topic for a given client.
  .kafka.assignNewTopicPartition                  Create a new assignment from which data will be consumed.
  .kafka.commitOffsetsToTopicPartition            Commit new offsets on broker for partitions of a given topic for a given client.
  .kafka.deleteTopicPartitionFromAssignment       Delete pairs of topic and partition from the current assignment for a client.
  .kafka.getBrokerTopicConfig                     Broker topic information.
  .kafka.getCommittedOffsetsForTopicPartition     Retrieve committed offsets for the given topics and partitions.
  .kafka.getCurrentAssignment                     Return the current assignment for the consumer.
  .kafka.getEarliestOffsetsForTimes               Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets.
  .kafka.getPrevailingOffsets                     Get the prevailing offsets for given partitions (last consumed message+1).

  // System infomation
  .kafka.getKafkaThreadCount                      Get a number of threads being used by librdkafka.
  .kafka.version                                  Librdkafka version.
  .kafka.versionString                            Human readable librdkafka version.
```

For simplicity in each of the examples below it should be assumed that the user’s system is configured correctly, unless otherwise specified. For example:

1. If subscribing to a topic, this topic exists.
2. If an output is presented, the output reflects the system used in the creation of these examples.

## Client functionality

The following functions relate to the creation of consumers and producers and their manipulation/interrogation.

### `.kafka.deleteClient`

_Close a consumer and destroy the associated Kafka handle to client. All registered callback for this client are removed._

Syntax: `.kafka.deleteClient[client_idx]`

Where

- `client_idx` is an integer denoting the index of the client to be deleted.

returns null on successful deletion of a client. If client unknown, signals `'unknown client`.

```q
/Client exists
q).kafka.getClientName[0i]
`rdkafka#consumer-1
q).kafka.deleteClient[0i]
q).kafka.ClientName[0i]
'unknown client
q)// Client can no longer be deleted
q).kafka.deleteClient[0i]
'unknown client
```

[*] Replacement of `.kfk.ClientDel`.

### `.kafka.getClientName`

_Get a name of client from client index._

Syntax: `.kafka.getClientName[client_index]`

Where

- `client_index` is an integer denoting the index of the client.

returns assigned client name.

```q
q).kafka.getClientName[0i]
`rdkafka#producer-1
q)// Client removed
q).kafka.getClientName[1i]
'unknown client
```

[*] Replacement of `.kfk.ClientName`.

### `.kafka.getOutQueueLength`

_Current number of messages that are queued for publishing._

Syntax: `.kafka.getOutQueueLength[client_idx]`

Where

- `client_idx` is the integer denoting the index of a client whose number of queued messages is checked.

returns as an int the number of messages in the queue.

```q
q).kafka.getOutQueueLength[producer]
5i
```

[*] Replacement of `.kfk.OutQLen`.

### `.kafka.newConsumer`

_Create a consumer according to user-defined configuration._

Syntax: `.kafka.newConsumer[config;timeout]`

Where

- `config` is a dictionary user-defined configuration.
- `timeout` is an integer value denoting the timeout (in milliseconds) to wait for a response from a kafka broker.

returns an integer denoting the index of the consumer.

```q
q)kafka_cfg
metadata.broker.list  | localhost:9092
group.id              | 0
queue.buffering.max.ms| 1
fetch.wait.max.ms     | 10
statistics.interval.ms| 10000
enable.auto.commit    | false
q).kafka.newConsumer[kafka_cfg; 5000i]
0i
```

[*] Replacement of `.kfk.Consumer`.

### `.kafka.newProducer`

_Create a producer according to user-defined configuration._

Syntax: `.kafka.newProducer[config;timeout]`

Where

- `config` is a user-defined dictionary configuration.
- `timeout` is an integer value denoting the timeout (in milliseconds) to wait for a response from a kafka broker.

returns an integer denoting the index of the producer.

```q
q)kafka_cfg
metadata.broker.list  | localhost:9092
statistics.interval.ms| 10000
queue.buffering.max.ms| 1
fetch.wait.max.ms     | 10
q).kafka.newProducer[kafka_cfg; 5000i]
0i
```

[*] Replacement of `.kfk.Producer`.

### `.kafka.SetLogLevel`

_Set the maximum logging level for a client._

Syntax: `.kafka.SetLogLevel[client_idx;level]`

Where

- `client_idx` is an integer denoting the client index.
- `level` is an int/long/short denoting the syslog severity level.

returns a null on successful application of function.

```q
q)show client
0i
q).kafka.SetLogLevel[client;7]
```

[*] Replacement of `.kfk.SetLoggerLevel`.

## Producer functionality

### `.kafka.publish`

_Publish a message to a defined topic._

Syntax: `.kafka.publish[topic_idx;partition;data;key]`

Where

- `topic_idx` is the integer denoting the index of the topic to be published on.
- `partition` is an integer denoting the target partition.
- `data` is a string or bytes which incorporates the payload to be published.
- `key` is a string or bytes to be passed with the message to the partition denoting the message key.

returns a null on successful publication.

```q
q)producer:.kafka.newProducer[kafka_cfg; 5000i]
q)test_topic:.kafka.newTopic[producer;`test;()!()]
// partition set as -1i denotes an unassigned partition
q).kafka.publish[test_topic;-1i;string .z.p;""]
q).kafka.publish[test_topic;-1i;string .z.p;"test_key"]
```

[*] Replacement of `.kfk.Pub`.

### `.kafka.publishBatch`

_Publish a batch of messages to a defined topic._

Syntax: `.kafka.publishBatch[topic_idx;partitions;data;keys]`

Where

- `topic_idx` is an integer denoting the topic (previously created) to be published on.
- `partitions` is an integer denoting a partition to which all messages are sent, or a list of integer denoting the target partitions for each message.
- `data` is a compound list payload containing either bytes or string.
- `keys` is an empty string for auto key on all messages or a key per message as a compound list of bytes or string.

returns an integer list denoting the status for each message (zero indicating success)

```q
q)batchMsg :("test message 1";"test message 2")
q)batchKeys:("Key 1";"Key 2")
q)// Send two messages to any partition using default key
q).kafka.publishBatch[;.kafka.PARTITION_UA;batchMsg;""] each (topic1; topic2)
q)// Send 2 messages to partition 0 for each topic using default key
q).kafka.publishBatch[;0i;batchMsg;""]each(topic1;topic2)
q)// Send 2 messages the first to separate partitions using generated keys
q).kafka.publishBatch[;0 1i;batchMsg;batchKeys]each(topic1;topic2)
```

[*] Replacement of `.kfk.BatchPub`.

### `.kafka.publishWithHeaders`

_Publish a message to a defined topic, with an associated header._

Syntax: `.kafka.publishWithHeaders[producer_idx;topic_idx;partition;data;keys;headers]`

Where

- `producer_idx` is an integer denoting the index of a producer.
- `topic_idx` is the integer denoting the index of the topic to be published on.
- `partition` is an integer denoting the target partition.
- `data` is a string or bytes which incorporates the payload to be published.
- `keys` is a string or bytes to be passed with the message to the partition denoting the message key.
- `headers` is a dictionary mapping a header name as a symbol to a byte array or string.

returns a null on successful publication, errors if version conditions not met

```q
q)// Create an appropriate producer
q)producer:.kafka.newProducer[kafka_cfg; 5000i]
q)// Create a topic
q)test_topic:.kafka.newTopic[producer;`test;()!()]
q)// Define the target partition as unassigned
q)partition:.kafka.PARTITION_UA
q)// Define an appropriate payload
q)payload:"hello from a producer"
q)// Define the headers to be added
q)headers:`header1`header2!("test1";"test2")
q)// Publish a message
q).kafka.publishWithHeaders[producer; test_topic; partition; payload; ""; headers]
```

!!!Note "Support for functionality"
	
	This functionality is only available for versions of librdkafka >= 0.11.4, use of a version less than this does not allow this 

[*] Replacement of `.kfk.PubWithHeaders`.

## Consumer functionality

### `.kafka.getConsumerGroupMemberID`

_Client's broker-assigned member ID._

Syntax: `.kafka.getConsumerGroupMemberID[consumer_idx]`

Where

- `consumer_idx` is an integer denoting the index of a consumer.

returns the member ID assigned to the client.

```q
q).kafka.getConsumerGroupMemberID[0i]
`rdkafka-881f3ee6-369b-488a-b6b2-c404d45ebc7c
q).kafka.getConsumerGroupMemberID[1i]
'unknown client
```

[*] Replacement of `.kfk.ClientMemberId`.

### `.kafka.getCurrentSubscription`

_Get current topic subscription information for the consumer._

Syntax: `.kafka.getCurrentSubscription[consumer_idx]`

Where

- `consumer_idx` is the integer value denoting the index of a consumer.

returns a table with the topic, partition, offset and metadata of the most recent subscription.

```q
q)consumer:.kafka.newConsumer[kafka_cfg; 5000i];
q).kafka.subscribe[consumer;`test2]
q).kafka.getCurrentSubscription[snsumer]
topic partition offset metadata
-------------------------------
test2 -1        -1001  ""
```

[*] Replacement of `.kfk.Subscription`.

### `.kafka.subscribe`

_Subscribe to a given topic with its partitions (and offsets)._

Syntax: `.kafka.subscribe[consumer_idx;topic]`

Where

- `consumer_idx` is an integer value denoting the index of a consumer.
- `topic` is a symbol denoting the topic being subscribed to.

returns a null on successful execution.

!!! note "Subscribing in advance"

    Subscriptions can be made to topics that do not currently exist.

!!! note "Multiple subscriptions"

    As of v1.4.0 multiple calls to `.kafka.Sub` for a given client will allow for consumption from multiple topics rather than overwriting the subscribed topic.

```q
q)client:.kafka.newConsumer[kafka_cfg; 5000i]
q)// List of topics to be subscribed to
q)topic_list:`test`test1`test2
q).kafka.subscribe[client] each topic_list
```

[*] Replacement of `.kfk.Sub`.

### `.kafka.unsubscribe`

_Unsubscribe from all topics associated with the consumer and remove consume-topic callback._

Syntax: `.kafka.unsubscribe[consumer_idx]`

Where

- `consumer_idx` is the integer representating the index of a consumer.

returns a null on successful execution; signals an error if client is unknown.

```q
q)consumer
0i
q).kafka.unsubscribe[consumer]
```

[*] Replacement of `.kfk.Unsub`.

## Callback Registration

### `.kafka.registerErrorCallback`

_Register an error callback associated with a specific client._

Syntax: `.kafka.registerErrorCallback[clid;callback]`

Where

- `client_idx` is the integer value denoting the index of a client to which the callback is to be registered.
- `callback` function taking 3 arguments which will be triggered on errors associated with the client. The parameters of this function are:
  - `client_idx`: integer denoting the index of a client.
  - `error_code`: integer denoting an error status code in Kafka.
  - `reason`: string denoting a reason for the error.

returns a null on successful execution.

```q
q)// Attempt to create a consumer which will fail
q)consumer1: .kafka.newConsumer[`metadata.broker.list`group.id!`foobar`0; 5000i]
q)consumer1
0i
q)// Attempt to create another failing consumer
q)consumer2: .kafka.Consumer[`metadata.broker.list`group.id!`foobar`0; 5000i]
q)consumer2
1i
q)"(1i;-193i;\"foobar:9092/bootstrap: Failed to resolve 'foobar:9092': nodename nor servnam..
"(1i;-187i;\"1/1 brokers are down\")"
q)// Attempt to create a consumer that will fail
q)consumer3:.kafka.newConsumer[`metadata.broker.list`group.id!`foobar`0]
q).kafka.registerErrorCallback[consumer3;{[cid;error_code;reason] show error_code;}]
q)-193i
-187i
```

[*] Replacement of `.kfk.errcbreg`.

### `.kafka.registerThrottleCallback`

_Register an throttle callback associated with a specific client._

Syntax: `.kafka.registerThrottleCallback[client_idx;callback]`

Where

- `client_idx` is the integer value denoting the index of a client to which the callback is to be registered.
- `callback` function taking 4 arguments which will be triggered on throttling associated with the client. These parameters represent:
  - `client_idx`: integer denoting the index of a client.
  - `broker_name`: string representing a broker name.
  - `broker_id`: integer denoting a broker ID.
  - `throttle_time`: integer denoting the accepted throttle time in milliseconds.

returns a null on successful execution and augments the dictionary `.kafka.errclient` mapping client id t
o callback

```q
q)client
0i
q)// Add a throttle client associated specifically with client 0
q).kafka.throttlecbreg[client;{[client_idx;broker_name;broker_id;throttle_time] -2 -3!(client_idx; throttle_time);}]
q)// Display the updated throttle callback logic
```

[*] Replacement of `.kfk.throttlecbreg`.

### `.kafka.registerConsumeTopicCallback`

_Register a topic consumption callback associated with a specific client-topic pair._

Synatx: `.kafka.registerConsumeTopicCallback[consumer_idx; topic; callback]`

Where

- `consumer_idx`:is an integer value denoting the index of a consumer.
- `topic`: is a symbol topic name for which calback is to be set.
- `callback`: Callback function.

```q
q)consumer
0i
q)topic
`test
q)topic_cb
{[consumer;msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.p;
  data1,::enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b]
}
q).kafka.subscribe[consumer;topic]
q).kafka.registerConsumeTopicCallback[consumer; topic; topic_cb consumer]
```

### `.kafka.log_cb`

_User custom callback for log message._

Syntax: `.kafka.log_cb:[level;fac;buf]`

Where

- `level`: is an integer denoting log level.
- `fac`: is a string.
- `buf`: is a string.

Exemple implementation is below:

```q

LOG: ();
.kafka.log_cb:{[level;fac;buf]
  LOG,: `level`fac`buf!(level; fac; buf);
 }

```

[*] Replacement of `.kfk.logcb`.

### `.kafka.offset_commit_cb`

_User custom callback for offset commit._

Syntax: `.kafka.offset_commit_cb:[consumer_idx;error;offsets]`

Where

- `consumer_idx`: is an interger denoting consumer index.
- `error`: is string denoting a error message.
- `offsets`: is a list of dictionary denoting topic-partition information dictionaries.

Example implementation is below:

```q

.kafka.offset_commit_cb:{[consumer_idx;error;offsets]
  $[
    error ~ "Success";
    -1 "committed:", .Q.s1 offsets;
    -2 "commit error: ", error
  ];
 };

```

[*] Replacement of `.kfk.offsetcb`.

### `.kafka.dr_msg_cb`

_User custom callback for message delivery notification._

Syntax:`.kafka.dr_msg_cb:[producer_idx;message]`

Where

- `producer_idx`: is an integer denoting an index of producer.
- `message`: is a dictionary denoting the information conatined in delivery report.

Example implementation is below:

```q

.kafka.dr_msg_cb:{[producer_idx; message]
  $["" ~ message `error;
    -1 "delivered:", .Q.s1 (message `msgtime; message `topic; "c"$message `data);
    -2 "delivery error:", message `error
  ];
 }

```

[*] Replacement of `.kfk.drcb`.

## Topic functionality

### `.kafka.getTopicName`

_Returns the name of a topic._

Syntax: `.kafka.getTopicName[topic_idx]`

Where

- `topic_idx` is the integer denoting the index of a topic.

returns as a symbol the name of the requested topic.

```q
q)producer
0i
q)topic1:.kafka.newTopic[producer;`test1;()!()]
q)topic2:.kafka.newTopic[producer;`test2;()!()]
q).kafka.getTopicName[topic1]
`test1
q).kafka.getTopicName[topic2]
`test2
```

[*] Replacement of `.kfk.TopicName`.

### `.kafka.deleteTopic`

_Delete a currently defined topic._

Syntax: `.kafka.deleteTopic[topic]`

Where

- `topic` is the integer value denoting the index of a topic to be deleted.

returns a null if a topic is deleted sucessfully.

```q
q)producer
0i
q).kafka.newTopic[producer;`test;()!()]
0i
q)topic
0i
q).kafka.deleteTopic[topic]
q)// topic now no longer available for deletion
q).kafka.deleteTopic[topic]
'unknown topic
```

[*] Replacement of `.kfk.TopicDel`.

### `.kafka.newTopic`

_Create a topic on which messages can be sent._

Syntax: `.kafka.newTopic[producer_idx;topic;config]`

Where

- `producer_idx` is an integer denoting the index of a producer on which the topic is produced
- `topic` is the desired topic name to be assigned to the topic as a symbol
- `sconfig` is a dictionary denoting a user-defined topic configuration, to use default set this to `()!()`

returns an integer denoting the value given to the assigned topic.

```q
q)producer:.kafka.newProducer[kafka_cfg; 5000i]
q).kafka.newTopic[producer;`test1;()!()]
0i
q).kafka.newTopic[producer;`test2;()!()]
1i
```

[*] Replacement of `.kfk.Topic`.

## Offset/Topic-partition functionality

The following functions relate to use of offsets within the API to ensure records are read correctly from the broker.

!!! note "Multiple topic offset assignment"

    As of v1.4.0 offset functionality can now handle calls associated with multiple topics without overwriting previous definitions. To apply the functionality this must be called for each topic.

### `.kafka.addTopicPartitionToAssignment`

_Add pairs of topic and partition to the current assignment for a client._

Syntax: `.kafka.addTopicPartitionToAssignment[client_idx;topic_to_partition]`

Where

- `client_idx` is an integer denoting the client id which the assignment is to applied.
- `topic_to_partition` is a dictionary mapping topic name as a symbol to partition as an int which is to be added to the current assignment.

returns a null on successful execution, will display inappropriate assignments if necessary

```q
q)consumer
0i
q)// Create a new assignment
q).kafka.assignNewTopicPartition[consumer;`test1`test2!0 0i]
q)// Retrieve the current assignment
q).kafka.getCurrentAssignment[consumer]
topic partition offset metadata
-------------------------------
test1 0         -1001  ""      
test2 0         -1001  ""      
// Add new assignments to the current assignment
q).kafka.addTopicPartitionToAssignment[consumer;`test1`test2!1 1i]
q)// Retrieve the current assignment
q).kafka.getCurrentAssignment[consumer]
topic partition offset metadata
-------------------------------
test1 1         -1001  ""      
test1 0         -1001  ""      
test1 1         -1001  ""      
test2 0         -1001  ""      
q)// Attempt to assign an already assigned topic partition pair
q).kafka.addTopicPartitionToAssignment[cid;`test1`test2!1 1i]
`test1 1i
`test2 1i
'The above topic-partition pairs already exist, please modify dictionary
```

[*] Replacement of `.kfk.AssignAdd`.

### `.kafka.assignNewOffsetsToTopicPartition`

_Create a new assignment from which data will be consumed._

Syntax: `.kafka.assignNewOffsetsToTopicPartition[consumer_idx;topic;new_part_to_offset]`

Where

- `consumer_idx` is the integer value associated with the consumer ID.
- `topic` is a symbol denoting the topic name.
- `new_part_to_offset` is a dictionary with key denoting the partition and value denoting where to start consuming the partition.

returns a null on successful execution.

```q
q).kafka.OFFSET_END
-2
q).kafka.assignNewOffsetsToTopicPartition[client; `test; enlist[0i]!enlist .kafka.OFFSET_END]
```

!!! note "Last-committed offset"

  	In the above examples an offset of -1001 is a special value. It indicates the offset could not be determined and the consumer will read from the last-committed offset once one becomes available.

[*] Replacement of `.kfk.AssignOffsets`.

### `.kafka.assignNewTopicPartition`

_Create a new assignment from which data is to be consumed._

Syntax: `.kafka.assignNewTopicPartition[consumer_idx;topic_to_partiton]`

Where

- `consumer_idx` is an integer denoting the index of a consumer to which the assignment is to applied.
- `topic_to_partiton` is a dictionary mapping topic name as a symbol to partition as an int which is to be assigned.

returns a null on successful execution

```q
q)consumer
0i
q).kafka.assignNewTopicPartition[consumer; `test1`test2!0 1i]
```

[*] Replacement of `.kfk.Assign`.

### `.kafka.commitOffsetsToTopicPartition`

_Commit offsets on broker for provided partitions and offsets._

Syntax: `.kafka.commitOffsetsToTopicPartition[conssumer_idx;topic;part_to_offsets;is_async]`

Where

- `consumer_idx` is the integer value denoting the index of a consumer.
- `topic` is a symbol topic name.
- `part_to_offsets` is a dictionary of partitions(int) and offsets (long)
- `is_async` is a boolean. `1b` to process asynchronusly. If `is_async` is `0b` this operation will block until the broker offset commit is done.

returns a null on successful commit of offsets.

See the example of [`.kafka.registerConsumeTopicCallback`](#kafkaregistconsumetopiccallback).

[*] Replacement of `.kfk.CommitOffsets`.

### `.kafka.deleteTopicPartitionFromAssignment`

_Delete pairs of topic and partition from the current assignment for a client._

Syntax: `.kafka.deleteTopicPartitionFromAssignment[client_idx;topic_to_partition]`

Where

- `client_idx` is an integer denoting the client id which the assignment is to applied.
- `topic_to_partition` is a dictionary mapping topic name as a symbol to partition as an int to be removed.

returns a null on successful execution, will display inappropriate assignment deletion if necessary

```q
q)consumer
0i
q)// Create a new assignment
q).kafka.assignNewTopicPartition[consumer;`test1`test1`test2`test2!0 1 0 1i]
q)// Retrieve the current assignment
q).kafka.getCurrentAssignment[consumer]
topic partition offset metadata
-------------------------------
test1 0         -1001  ""
test2 1         -1001  ""
test2 0         -1001  ""
test2 1         -1001  ""
q)// Add new assignments to the current assignment
q).kafka.deleteTopicPartitionFromAssignment[consumer;`test1`test2!1 1]
q)// Retrieve the current assignment
q).kafka.getCurrentAssignment[cid]
topic partition offset metadata
-------------------------------
test1 0         -1001  ""
test2 0         -1001  ""
q)// Attempt to assign an already unassigned topic partition pair
q).kafka.deleteTopicPartitionFromAssignment[consumer;`test1`test2!1 1i]
`test1 1i
`test2 1i
'The above topic-partition pairs cannot be deleted as they are not assigned
```

[*] Replacement of `.kfk.AssignDel`.

### `.kafka.getBrokerTopicConfig`

_Information about configuration of brokers and topics._

Syntax: `.kafka.getBrokerTopicConfig[client_idx;timeout]`

Where

- `client_idx` is the integer denoting the index of a client.
- `timeout` is an integer value denoting the timeout (in milliseconds) to wait for a response from a kafka broker.

returns a dictionary with information about the brokers and topics.

```q
q)show producer_meta:.kafka.getBrokerTopicConfig[producer; 5000i]
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

[*] Replacement of `.kfk.Metadata`.

### `.kafka.getCommittedOffsetsForTopicPartition`

_Retrieve the last-committed offset for a topic on a particular partition._

Syntax: `.kafka.getCommittedOffsetsForTopicPartition[consumer_idx;topic;partitions]`

Where

- `consumer_idx` is the integer value denoting the index of a consumer.
- `topic` is a symbol denoting the topic.
- `partitions` is a list of int denoting partitions.

returns a table containing the offset for a particular partition for a topic.

```q
q)consumer
0i
q)topic:`test
q).kafka.CommittedOffsets[consumer; topic; enlist 0i]
topic partition offset metadata
-------------------------------
test  0         26480  ""
test  1         -1001  ""
q).kafka.commitOffsetsToTopicPartition[consumer; topic; enlist[0i]!enlist 26481; 1b]
q).kafka.CommittedOffsets[client; topic; enlist 0i]
topic partition offset metadata
-------------------------------
test  0         26481  ""
test  1         -1001  ""
```

[*] Replacement of `.kfk.CommittedOffsets`.

### `.kafka.getCurrentAssignment`

_Retrieve the current assignment for a specified client._

Syntax: `.kafka.getCurrentAssignment[client_idx]`

Where

- `client_idx` is an integer denoting the client id from which the assignment is to be retrieved.

returns a list of dictionaries describing the current assignment for the specified client

```q
q)consumer
0i
q)// Attempt to retrieve assignment without a current assignment
q).kafka.getCurrentAssignment[consumer]
topic partition offset metadata
-------------------------------
q)// Create a new assignment
q).kafka.assignNewTopicPartition[consumer;`test1`test2!0 1i]
q)// Retrieve the new current assignment
q).kafka.getCurrentAssignment[consumer]
topic partition offset metadata
-------------------------------
test1 0         -1001  ""
test2 1         -1001  ""
```

[*] Replacement of `.kfk.Assignment`.

### `.kafka.getEarliestOffsetsForTimes`

_Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets._

Syntax: `.kafka.getEarliestOffsetsForTimes:[consumer_idx;topic;part_to_offset;timeout]`

Where

- `consumer_idx` is an integer value denoting the index of a client.
- `topic` is a symbol denoting a topic name.
- `part_to_offset` is a dictionary mapping from partition as an int to offset to use as start time. The supported type ff offset are:
  - long
  - date
  - timestamp
- `timeout` is a number denoting a timeout (milliseconds) for querying.

```q
q).kafka.getEarliestOffsetsForTimes[consumer; `topic1; enlist[1i]!enlist .z.p-0D00:01:00.000000000; 1000]
q).kafka.getEarliestOffsetsForTimes[consumer; `topic1; enlist[1i]!enlist .z.p-0D00:01:00.000000000; 1000]
topic  partition offset metadata
--------------------------------
topic1 1         20     ""      
```

[*] Replacement of `.kfk.offsetForTimes`.

### `.kafka.getPrevailingOffsets`

_Get the prevailing offsets for given partitions (last consumed message+1)._

Syntax: `.kafka.getPrevailingOffsets[consumer_idx;topic;partitions]`

Where

- `consumer_idx` is the integer value denoting the index of a consumer.
- `topic` is a symbol denoting the topic name.
- `partitions` is a list of int denoting partitions.

returns a table containing the current offset and partition for the topic of interest.

```q
q)consumer:.kafka.newConsumer[kafka_cfg; 5000i];
q)topic:`test
q).kafka.PositionOffsets[client;topic;0 1i]
topic partition offset metadata
-------------------------------
test  0         26482  ""
test  1         -1001  ""
```

!!! note "Valid only once for each pusbish"

    As this function sets the current position to the last consumed offset+1, you will see -1001 from the second execution unless a new mesage is consumed.

[*] Replacement of `.kfk.PositionOffsets`.

## System information

### `.kafka.getKafkaThreadCount`

_The number of threads that are being used by librdkafka._

Syntax: `.kafka.getKafkaThreadCount[]`

returns the number of threads currently in use by `librdkafka`.

```q
q).kafka.getKafkaThreadCount[]
5i
```

[*] Replacement of `.kfk.ThreadCount`.

### `.kafka.version`

_Integer value of the librdkafka version._

Syntax: `.kafka.version[]`

Returns the integer value of the `librdkafka` version being used within the interface.

```q
q).kafka.version[]
16777471i
```

[*] Replacement of `.kfk.Version`.

### `.kafka.versionString`

_Human readable librdkafka version._

Syntax: `.kafka.versionString[]`

Returns a string denoting the version of `librdkafka` that is being used within the interface.

```q
q).kafka.versionString[]
"1.1.0"
```

[*] Replacement of `.kfk.VersionSym`.
