# ![Apache Kafka](kafka.png) Kafka function reference 

The kdb+/Kafka interface is a thin wrapper for kdb+ around the [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Apache Kafka](https://kafka.apache.org/). 

## **`.kafka.`** Kafka interface 

System information

- [`Metadata`](#metadata) Broker Metadata
- [`Version`](#version) Librdkafka version
- [`VersionSym`](#versionsym) Human readable Librdkafka version
- [`ThreadCount`](#threadcount) Number of threads being used by librdkafka
- [`Errors`](#errors) Librdkafka errors description

Topics

- [`Topic`](#topic) Create a topic on which messages can be sent
- [`TopicDel`](#topicdel) Delete a defined topic
- [`TopicName`](#topicname) Topic Name

Callback modifications

- [`SetPerClientErrorCb`](#setperclienterrorcb) Register an error callback associated with a specific client
- [`SetErrorCb](#seterrorcb) Set error handling callback
- [`ResetErrorCb](#reseterrorcb) Reset error handling callback to default
- [`SetPerClientThrottleCb`](#setperclientthrottlecb) Register a throttle callback associated with a specific client
- [`SetThrottleCb`](#setthrottlecb) Set throttle callback
- [`ResetThrottleCb`](#resetthrottlecb) Reset throttle callback to default
- [`SetStatCb`](#setstatcb) Set statistics callback
- [`ResetStatCb`](#resetstatcb) Reset statistics callback to default
- [`SetLogCb`](#setlogcb) Set logger callback
- [`ResetLogCb`](#resetlogcb) Set logger callback to default
- [`SetDeliveryCb`](#setdeliverycb) Set delivery report callback (publisher only)
- [`ResetDeliveryCb`](#resetdeliverycb) Reset delivery report callback to default (publisher only)
- [`SetOffsetCb`](#setoffsetcb) Set offset commit callback for use with consumer groups (subscriber only)
- [`ResetOffsetCb`](#resetoffsetcb) Reset offset commit callback for use with consumer groups tp default (subscriber only)
- [`SetTopicCb`](#settopiccb) Called for each message with defined topic received (subscriber only)
- [`SetConsumeCb`](#setconsumecb) Set consume callback for each message received (subscriber only)
- [`ResetConsumeCb`](#resetconsumecb) Reset consume callback to default (subscriber only)

Getters
- [`GetStats`](#getstats) Get statistics recorded by default
- [`GetClientTopicMap`](#getclienttopicmap) Get mapping between clients and topics
- [`GetClientTypeMap`](#getclienttypemap) Get mapping between client the client type

Clients (Consumer or Producer)

- [`ClientDel`](#clientdel) Close consumer and destroy Kafka handle to client
- [`ClientName`](#clientname) Kafka handle name
- [`ClientMemberId`](#clientmemberid) Client's broker assigned member ID
- [`Consumer`](#consumer) Create a consumer according to defined configuration
- [`Producer`](#producer) Create a producer according to defined configuration
- [`SetLoggerLevel`](#setloggerlevel) Set the maximum logging level for a client

Offsets

- [`CommitOffsets`](#commitoffsets) Commit offsets on broker for provided partition list
- [`PositionOffsets`](#positionoffsets) Current offsets for topics and partitions
- [`CommittedOffsets`](#committedoffsets) Retrieve committed offsets for topics and partitions
- [`queryWatermark`](#querywatermark) Query broker for low (oldest/beginning) and high (newest/end) offsets for partition.

Publishing

- [`BatchPub`](#batchpub) Publish a batch of data to a defined topic
- [`Pub`](#pub) Publish a message to a defined topic
- [`PubWithHeaders`](#pubwithheaders) Publish a message to a defined topic with a header 
- [`OutQLen`](#outqlen) Current out queue length 
- [`Flush`](#flush) Wait until all outstanding produce requests, et.al, are completed

[Subscriptions](#subscriptions)

- [Dynamic](#dynamic) assigned subscriptions
  - [`Sub`](#sub) Subscribe to a defined topic
  - [`Subscribe`](#subscribe) Subscribe from a consumer to a topic with a specified callback
  - [`Subscription`](#subscription) Most recent topic subscription
- [Manual](#manual) assigned partitions/offsets
  - [`Assign`](#assign) Create a new assignment from which data will be consumed
  - [`AssignOffsets`](#assignoffsets) Assignment of partitions to consume
  - [`AssignAdd`](#assignadd) Add new assignments to the current assignment
  - [`AssignDel`](#assigndel) Remove topic partition assignments from the current assignments
  - [`Assignment`](#assignment) Return the current assignment
- General Subscription Functions
  - [`Unsub`](#unsub) Unsubscribe from a topic

[Polling](#polling)

- [`MaxMsgsPerPoll`](#maxmsgsperpoll) Set the maximum number of messages per poll
- [`Poll`](#poll) Manually poll the feed

## System information

### `Metadata`

_Information about configuration of brokers and topics_

```q
.kafka.Metadata id
```

Where `id` is a consumer or producer ID, returns a dictionary populated with the following info:

-   `orig_broker_id` (int): Broker originating this metadata
-   `orig_broker_name` (symbol): Name of originating broker
-   `brokers` (list of dictionaries): Info on current brokers
-   `topics` (list of dictionaries): Info on current topics

When using a consumer, the metadata response information may trigger a re-join if any subscribed topics have changed partition count or existence state.

Example:

```q
q)show producer_meta:.kafka.Metadata producer
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

```q
.kafka.ThreadCount[]
```

returns the number of threads currently in use by `librdkafka`.

```q
q).kafka.ThreadCount[]
5i
```

### `Version`

_Version of librdkafka (integer)_

```q
.kafka.Version
```

Returns the `librdkafka` version (integer) used within the interface. Can be parsed as follows (according to the [kafka version format](https://docs.confluent.io/legacy/platform/5.5.15/clients/librdkafka/rdkafka_8h.html#aa2e242fb8620a32b650a40575bc7f98e))

```
q).kafka.Version
33751295i
q)"." sv 2 cut -8$"0123456789abcdef" 16 vs .kafka.Version
" 2.03.00.ff"
```

### `VersionSym`

_Version of librdkafka (symbol)_

```q
.kafka.VersionSym[]
```

Returns the `librdkafka` version (symbol) used within the interface.

```q
q).kafka.VersionSym[]
`1.1.0
```

### `Errors`

_Description of librdkafka error codes (table)_

```q
.kafka.Errors[]
```

Returns the description of errors (table) that could occur within the interface.

```q
q).kafka.Errors[]
errid code                   desc                                             
------------------------------------------------------------------------------
-200  _BEGIN                 ""                                               
-199  _BAD_MSG               "Local: Bad message format"                      
-198  _BAD_COMPRESSION       "Local: Invalid compressed data"                 
-197  _DESTROY               "Local: Broker handle destroyed"
...
```

## Topics

### `Topic`

_Create a topic on which messages can be sent_

```q
.kafka.Topic[id;topic;cfg]
```

Where

-   `id` is a consumer or producer ID
-   `topic` is a name to be assigned to the topic (symbol)
-   `cfg` is a user-defined topic configuration (dictionary) for adding/overloading configuration. Both keys and values must be of symbol,string,char or symbol list type. Default: `()!()`

returns the topic ID (integer).

```q
q)consumer:.kafka.Consumer[kfk_cfg]
q).kafka.Topic[consumer;`test;()!()]
0i
q).kafka.Topic[consumer;`test1;()!()]
1i
```

:point_right: 
[edenhill/librdkafka/CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md) for a list of cfg options. Note: column indicating whether only used by a [consumer](#consumer) or [producer](#producer) rather than a topic.

### `TopicDel`

_Delete a currently defined topic_

```q
.kafka.TopicDel topic
```

Where `topic` is a topic ID, deletes the topic and returns a null.

```q
q).kafka.Topic[0i;`test;()!()]
0i
q).kafka.TopicDel[0i]
q)/ topic now no longer available for deletion
q).kafka.TopicDel[0i]
'unknown topic
```


### `TopicName`

_Returns the name of a topic_

```q
.kafka.TopicName tpcid
```

Where `tpcid` is a topic ID, returns its name  as a symbol.

```q
q).kafka.Topic[0i;`test;()!()]
0i
q).kafka.Topic[0i;`test1;()!()]
1i
q).kafka.TopicName[0i]
`test
q).kafka.TopicName[1i]
`test1
```

## Callback Modifications

### `SetPerClientErrorCb`

_Register an error callback associated with a specific client_

```q
.kafka.SetPerClientErrorCb[clid;callback]
```

Where

-   `clid` is a client ID (integer)
-   `callback` is a ternary function

sets `callback` to be triggered by errors associated with the client, augments the dictionary `.kafka.errclient` mapping client ID to callback, and returns a null.

The arguments of `callback` are:

-   `cid`: ID of client for which this is called (integer)
-   `errInt`: error status code in Kafka (integer)
-   `reason`: error message (string)


```q
q)// Assignment prior to registration of new callback
q)// Attempt to create a consumer which will fail
q).kafka.Consumer[`metadata.broker.list`group.id!`foobar`0]
0i

q)// Update the default behavior to show the output
q).kafka.SetPerClientErrorCb[`;{[cid;errInt;reason]show(cid;errInt;reason);}]

q)// Attempt to create another failing consumer
q).kafka.Consumer[`metadata.broker.list`group.id!`foobar`0]
1i
q)1i
-193i
"foobar:9092/bootstrap: Failed to resolve 'foobar:9092': nodename nor servnam..
1i
-187i
"1/1 brokers are down"

q)// Start a new q session and register an error callback for cid 0
q).kafka.SetPerClientErrorCb[0i;{[cid;errInt;reason] show errInt;}]
q)// Attempt to create a consumer that will fail
q).kafka.Consumer[`metadata.broker.list`group.id!`foobar`0]
0i
q)-193i
-187i
```

### `SetErrorCb`

```q
.kafka.ResetErrorCb[cb]
```

where `cb` is a ternary function.

Default implementation:
```q
errcb:{[cid;errInt;reason]$[null f:errclient`$string cid;errclient.;f].(cid;errInt;reason)}
```

### `ResetErrorCb`

```q
.kafka.ResetErrorCb[]
```

Resets error callback to default. See [`SetErrorCb`](#seterrorcb).

### `SetPerClientThrottleCb`

_Register an throttle callback associated with a specific client_

```q
.kafka.SetPerClientThrottleCb[clid;callback]
```

Where

-   `clid` is a client ID (integer)
-   `callback` is a quaternary function

sets `callback` to be triggered on throttling associated with the client, 
augments the dictionary `.kafka.throttleclient` mapping client ID to callback,
and returns a null.

The arguments of `callback` are:

-   `cid`: ID (integer) of client for which this is called 
-   `bname`: broker name (string)
-   `bid`: broker ID (integer)
-   `throttleTime`: accepted throttle time in milliseconds (integer)

```q
q)// Assignment prior to registration of new callback 

q)// Update the default behavior to show the output
q).kafka.SetPerClientThrottleCb[`;{[cid;bname;bid;throttleTime]show(cid;bid);}]

q)// Add a throttle client associated specifically with client 0
q).kafka.SetPerClientThrottleCb[0i;{[cid;bname;bid;throttleTime]show(cid;throttleTime);}]
```

### `SetThrottleCb`

```q
.kafka.SetThrottleCb[cb]
```
where `cb` is function with 4 parameters.

Default implementation calls callback registered to the client in `.kafka.throttleclient` mapping or uses default.

```q
throttlecb:{[cid;bname;bid;throttleTime]
  $[null f:throttleclient`$string cid;throttleclient.;f].(cid;bname;bid;throttleTime)
  }
```

### `ResetThrottleCb`

```q
.kafka.ResetThrottleCb[]
```

Resets throttle callback to default. See [`SetThrottleCb`](#setthrottlecb).

### `SetStatCb`

_Statistics callback_

```q
statcb: {[j]}
.kafka.SetStatCb[statcb]
```

Where j is a json string (see [`.j.k`](https://code.kx.com/q/ref/dotj/#jk-deserialize) for parsing json in q). For more information on the format of json, see [https://github.com/confluentinc/librdkafka/wiki/Statistics](https://github.com/confluentinc/librdkafka/wiki/Statistics).

Set this callback to provide a new definition that suits your needs. Default is to store the last 100 stats. Access this table with
 `.kafka.GetStats[]` ([`GetStats`](#getstats))

The statistics callback is triggered every `statistics.interval.ms`.

Default implementation:

```q
statcb:{[j]
  s:.j.k j;
  if[all `ts`time in key s;
    s[`ts]:-10957D+`timestamp$s[`ts]*1000;
    s[`time]:-10957D+`timestamp$1000000000*s[`time]
    ];
  if[not `cgrp in key s;s[`cgrp]:()];
  .z.m.stats,:enlist s;
  delete from .z.M.stats where i<count[.z.m.stats]-100;}
```

### `ResetStatCb`

Resets statistics callback to default. See [`SetStatCb`](#setstatcb).

### `SetLogCb`

_Logger callback (logs from librdkafka)_

```q
.kafka.SetLogCb[cb]
```

Where cb is a ternary function. Parameters:

- `level` is log level (integer) as discussed in [`SetLoggerLevel`](#setloggerlevel)
- `fac` in the msg type (string)
- `buf` is the msg detail (string)

should be set to return nil.

Set this callback to provide a new definition that suits your needs. Default is to print to stdout.
```q
logcb:{[level;fac;buf] show -3!(level;fac;buf);}
```

### `ResetLogCb`

Resets log callback to default. See [`SetLogCb`](#setlogcb).

### `SetDeliveryCb`

_Delivery report callback_

```q
.kafka.SetDeliveryCb[{[cid;msg]}]
```

Where
- `cid` is the ID (integer) of client for which this is called 
- `msg` is the message details (as dictionary)

should be set to return nil. For publishing msgs only (i.e. client that is a producer).

Set this callback to provide a new definition that suits your needs. There is no default action.

The callback is called when a message is succesfully produced or if librdkafka encountered a permanent failure. Delivery errors occur when the retry count is exceeded, when the `message.timeout.ms` timeout is exceeded or there is a permanent error like RD_KAFKA_RESP_ERR_UNKNOWN_TOPIC_OR_PART.

Default implementation(noop):
```q
drcb:{[cid;msg]}
```

### `ResetDeliveryCb`

Resets delivery callback to default. See [`SetDeliveryCb`](#setdeliverycb).

### `SetOffsetCb`

_Offset commit callback for use with consumer groups_

```q
.kafka.SetOffsetCb[{[cid;err;offsets]}]
```

Where

- `cid` is the ID (integer) of client for which this is called 
- `err` error details (string) e.g. "Success" if ok
- `offsets` is a list of dictionaries, each containing details for each commit with the following details
  - `topic` (symbol)
  - `partition` (int)
  - `offset` (long)
  - `metadata` (string)

should be set to return nil. For subscribers only.

Set this callback to provide a new definition that suits your needs. There is no default action.

The results of automatic or manual offset commits will be scheduled for this callback. 
If no partitions had valid offsets to commit this callback will be called with err == RD_KAFKA_RESP_ERR__NO_OFFSET which is not to be considered an error.

The offsets list contains per-partition information:

- offset: committed offset (attempted)
- err: commit error

Default implementation(noop):
```q
offsetcb:{[cid;err;offsets]}
```

### `ResetOffsetCb`

Resets offset callback to default. See [`SetOffsetCb`](#setoffsetcb).

#### `SetTopicCb`

Sets callback per topic in `consumetopic` dictionary.

```q
.kafka.SetTopicCb{[msg]}
```
Where `msg` is the content of a message received (as dictionary) from any calls to the subscription on the topic.

Override this variable to provide a new definition that suits your needs. There is no default action.

e.g.
setting the callback to print each msg

```q
.kafka.SetTopicCb[`;{[msg]show msg;}]
```

will print as message as follows:

```q
mtype    | `
topic    | `test1
client   | 0i
partition| 0i
offset   | 1803
msgtime  | 2024.04.23D16:17:52.403000000
data     | 0x323032342e30342e32334431363a31373a35322e333938373134303030
key      | `byte$()
headers  | (`symbol$())!`symbol$()
```

### `SetConsumeCb`

_Main unary function called on consumption of data for both default and per topic callback. Called for each message received._

```q
.kafka.SetConsumeCb[cb]
```

If received message's topic has a callback set by `Subscribe` or `SetTopicCb`, calls callback, otherwise calls default (noop). 

Default implementation:
```q
consumecb:{[msg]$[null f:consumetopic msg`topic;consumetopic.;f]msg}
```

### `ResetConsumeCb`

Resets consume callback to default. See [`SetConsumeCb`](#setconsumecb).

### `GetStats`

```q
.kafka.GetStats[]
```

Get statistics recorded by default.

### `GetClientTopicMap`

```q
.kafka.GetClientTopicMap[]
```

Get mapping between clients and topics.

### `GetClientTypeMap`

```q
.kafka.GetClientTypeMap[]
```

Get mapping between client the client type.

## Clients

The following functions relate to the creation of consumers and producers and their manipulation/interrogation.

### `ClientDel`

_Close a consumer and destroy the associated Kafka handle to client_

```q
.kafka.ClientDel clid
```

Where  `clid` is the client to be deleted (integer), returns null on successful deletion. 
If client unknown, signals `'unknown client`.

This call will block until the consumer has revoked its assignment, committed offsets to broker, and left the consumer group (if applicable). The maximum blocking time is roughly limited to session.timeout.ms.

```q
/Client exists
q).kafka.ClientName 0i
`rdkafka#consumer-1
q).kafka.ClientDel 0i
q).kafka.ClientName 0i
'unknown client
/Client can no longer be deleted
q).kafka.ClientDel 0i
'unknown client
```

### `ClientMemberId`

_Returns this client's broker-assigned group member id_

```q
.kafka.ClientMemberId clid
```

Where `clid` is a client ID (integer), returns the member ID (symbol) assigned to the client, or signals `unknown client`.

> :warning: **Consumer processes only**
> 
> This function should be called only on a consumer process. 
> This is an [external limitation](https://docs.confluent.io/2.0.0/clients/librdkafka/rdkafka_8h.html#a856d7ecba1aa64e5c89ac92b445cdda6).

```q
q).kafka.ClientMemberId 0i
`rdkafka-881f3ee6-369b-488a-b6b2-c404d45ebc7c
q).kafka.ClientMemberId 1i
'unknown client
```

### `ClientName`

_Kafka handle name_

```q
.kafka.ClientName clid
```

Where `clid` is a client ID (integer), returns assigned client name (symbol) or signals `unknown client`.

```q
q).kafka.ClientName 0i
`rdkafka#producer-1
/Client removed
q).kafka.ClientName 1i
'unknown client
```

### `Consumer`

_Create a consumer according to user-defined configuration_

```q
.kafka.Consumer cfg
```

Where `cfg` is a dictionary for adding/overloading configuration. Both keys and values must be of symbol,string,char or symbol list type. Returns the ID of the consumer as an integer.

```q
q)kfk_cfg
metadata.broker.list  | localhost:9092
group.id              | 0
queue.buffering.max.ms| 1
fetch.wait.max.ms     | 10
statistics.interval.ms| 10000
q).kafka.Consumer kfk_cfg
0i
```

:point_right: 
[edenhill/librdkafka/CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md) for a list of cfg options (note: column indicating whether consumer/producer/both).

### `Producer`

_Create a producer according to user-defined configuration_

```q
.kafka.Producer cfg
```

Where `cfg` is a dictionary for adding/overloading configuration. Both keys and values must be of symbol,string,char or symbol list type. Returns the ID of the producer as an integer.

```q
q)kfk_cfg
metadata.broker.list  | localhost:9092
statistics.interval.ms| 10000
queue.buffering.max.ms| 1
fetch.wait.max.ms     | 10
q).kafka.Producer kfk_cfg
0i
```

:point_right: 
[edenhill/librdkafka/CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md) for a list of cfg options (note: column indicating whether consumer/producer/both).

### `SetLoggerLevel`

_Specifies the maximum logging level emitted by internal kafka logging and debugging_

```q
.kafka.SetLoggerLevel[clid;level]
```

Where

-   `clid` is the client ID (int)
-   `level` is the syslog severity level (int/long/short). Log levels are
    - 0 (emergency)
    - 1 (alert)
    - 2 (critical)
    - 3 (error)
    - 4 (warning)
    - 5 (notice)
    - 6 (info)
    - 7 (debug)

returns a null on successful application of function.

If the "debug" configuration property is set the log level is automatically adjusted to 7 (debug).

```q
q)show client
0i
q).kafka.SetLoggerLevel[client;7]
```

## Offset functionality

The following functions relate to use of offsets within the API to ensure records are read correctly from the broker.

> :note: **Multiple topic offset assignment**
>
> As of v1.4.0 offset functionality can now handle calls associated with multiple topics without overwriting previous definitions. To apply the functionality this must be called for each topic.

### `CommitOffsets`

_Commit offsets on broker for provided partitions and offsets_

```q
.kafka.CommitOffsets[clid;topic;part_offsets;block_commit]
```

Where

-   `clid` is a consumer client ID (int)
-   `topic` is a topic (symbol)
-   `part_offsets` is a dictionary of partitions(ints) and last received offsets (longs). The offset should be the offset where consumption will resume i.e. the last processed offset + 1
-   `block_commit` is whether commit will block until offset commit is complete (boolean)

returns a null on successful commit of offsets.

### `PositionOffsets`

_Current offsets for particular topics and partitions_

```q
.kafka.PositionOffsets[clid;topic;part_offsets]
```

Where

-   `clid` is the consumer ID (int)
-   `topic` is the topic (symbol)
-   `part_offsets` is a list of partitions (int, short, or long), or a dictionary of partitions (int) and offsets (long)

returns a table containing the current offset and partition for the topic of interest. The offset field of each requested partition will be set to the offset of the last consumed message + 1, or .kafka.OFFSET.INVALID (-1001) if there was no previous message.

In this context the last consumed message is the offset consumed by the current librdkafka instance and, in case of rebalancing, not necessarily the last message fetched from the partition.

```q
q)client:.kafka.Consumer kfk_cfg
q)TOPIC:`test
q)show seen:exec last offset by partition from data
0|0
// dictionary input
q).kafka.PositionOffsets[client;TOPIC;seen]
topic partition offset metadata
-------------------------------
test  0         26482  ""
// int list input
q).kafka.PositionOffsets[client;TOPIC;0 1i]
topic partition offset metadata
-------------------------------
test  0         26482  ""
test  1         -1001  ""
// long list input
q).kafka.PositionOffsets[client;TOPIC;0 1 2]
topic partition offset metadata
-------------------------------
test  0         26482  ""
test  1         -1001  ""
test  2         -1001  ""
```

### `CommittedOffsets`

_Retrieve the last-committed offset for a topic on a particular partition_

```q
.kafka.CommittedOffsets[clid;topic;part_offsets]
```

Where

-   `clid` is a consumer ID (integer)
-   `topic` is a topic (symbol)
-   `part_offsets` is a list of partitions (int, short, or long), or a dictionary of partitions (int) and offsets (long)

returns a table containing the offset for a particular partition for a topic.

Committed offsets will be returned according to the isolation.level configuration property, if set to read_committed (default) then only stable offsets for fully committed transactions will be returned, while read_uncommitted may return offsets for not yet committed transactions.

Offset will be set to .kafka.OFFSET.INVALID (-1001) if there was no stored offset for that partition.

```q
q)client:.kafka.Consumer[kfk_cfg];
q)TOPIC:`test
q)show seen:exec last offset by partition from data;
0|0
// dictionary input
q).kafka.CommittedOffsets[client;TOPIC;seen]
topic partition offset metadata
-------------------------------
test  0         26481  ""
// integer list input
q).kafka.CommittedOffsets[client;TOPIC;0 1i]
topic partition offset metadata
-------------------------------
test  0         26481  ""
test  1         -1001  ""
// long list input
q).kafka.CommittedOffsets[client;TOPIC;0 1]
topic partition offset metadata
-------------------------------
test  0         26481  ""
test  1         -1001  ""
```


### `queryWatermark`

_Query broker for low (oldest/beginning) and high (newest/end) offsets for partition_

```q
.kafka.queryWatermark[client;`test1;0;1000]
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

```q
.kafka.BatchPub[tpcid;partid;data;keys]
```

Where

-   `tpcid` is the topic (previously created) to be published on (integer)
-   `partid` is the target partition/s (integer atom or list). If partition is .kafka.PARTITION_UA the configured partitioner will be run for each message (slower), otherwise the messages will be enqueued to the specified partition directly (faster).
-   `data` is a mixed list payload containing either bytes or strings
-   `keys` is an empty string for auto key on all messages or a key per message as a mixed list of bytes or strings

returns an integer list denoting the status for each message (zero indicating success)

```q
q)batchMsg :("test message 1";"test message 2")
q)batchKeys:("Key 1";"Key 2")

q)// Send two messages to any partition using default key
q).kafka.BatchPub[;.kafka.PARTITION_UA;batchMsg;""]each(topic1;topic2)
0 0
0 0

q)// Send 2 messages to partition 0 for each topic using default key
q).kafka.BatchPub[;0i;batchMsg;""]each(topic1;topic2)
0 0
0 0

q)// Send 2 messages the first to separate partitions using generated keys
q).kafka.BatchPub[;0 1i;batchMsg;batchKeys]each(topic1;topic2)
0 0
0 0
```

### `Pub`

_Publish a message to a defined topic_

```q
.kafka.Pub[tpcid;partid;data;keys]
```

Where

-   `tpcid` is the topic to be published on (integer)
-   `partid` is the target partition (integer). Can be .kafka.PARTITION_UA (unassigned) for automatic partitioning using the topic's partitioner function, or a fixed partition (0..N)
-   `data` is the payload to be published (string)
-   `keys` is the message key (string) to be passed with the message to the partition 

returns a null on successful publication.

This is an asynchronous non-blocking API. See [`drcb`](#drcb) (delivery report callback) on how to setup a callback to be called once the delivery status (success or failure) is known.

Since producing is asynchronous, you should call [`Flush`](#flush) before you destroy the producer. Otherwise, any outstanding messages will be silently discarded.

When temporary errors occur, librdkafka automatically retries to produce the messages. Retries are triggered after `retry.backoff.ms` and when the leader broker for the given partition is available. Otherwise, librdkafka falls back to polling the topic metadata to monitor when a new leader is elected (see the `topic.metadata.refresh.fast.interval.ms` and `topic.metadata.refresh.interval.ms` configurations) and then performs a retry. A delivery error will occur if the message could not be produced within message.timeout.ms.

```q
q)producer:.kafka.Producer kfk_cfg
q)test_topic:.kafka.Topic[producer;`test;()!()]
/ partition set as -1i denotes an unassigned partition
q).kafka.Pub[test_topic;-1i;string .z.p;""]
q).kafka.Pub[test_topic;-1i;string .z.p;"test_key"]
```

### `PubWithHeaders`

_Publish a message to a defined topic, with an associated header_

```q
.kafka.PubWithHeader[clid;tpcid;partid;data;keys;hdrs]
```

Where

-   `clid` is a target client ID (integer)
-   `tpcid` is the topic to be published on (integer)
-   `partid` is the target partition (integer)
-   `data` is the payload to be published (string)
-   `keys` is the message key (string) to be passed with the message to the partition 
-   `hdrs` is a dictionary mapping a header name (symbol) to a byte array or string

returns a null on successful publication; errors if version conditions not met.

See [`Pub`](#pub) for further details of how messages are published.

```q
// Create an appropriate producer
producer:.kafka.Producer kfk_cfg

// Create a topic
test_topic:.kafka.Topic[producer;`test;()!()]

// Define the target partition as unassigned
part:-1i

// Define an appropriate payload
payload:string .z.p

// Define the headers to be added
hdrs:`header1`header2!("test1";"test2")

// Publish a message to client #0 with a header but no key
.kafka.PubWithHeaders[0i;test_topic;part;payload;"";hdrs]

// Publish a message to client #1 with headers and a key
.kafka.PubWithHeaders[1i;test_topic;part;payload;"test_key";hdrs]
```

> **Support for functionality**
>     
> This functionality is only available for versions of `librdkafka` ≥ 0.11.4

### `OutQLen`

_Current number of messages that are queued for publishing_

```q
.kafka.OutQLen prid
```

Where `prid` is the integer value of the producer which we wish to check the number of queued messages, returns as an int the number of messages in the queue.

The out queue length is the sum of

- number of messages waiting to be sent to, or acknowledged by, the broker
- number of delivery reports waiting to be served
- number of callbacks waiting to be served
- number of events waiting to be served by background queue

An application should wait for the return value of this function to reach zero before terminating to make sure outstanding messages, requests (such as offset commits), callbacks and events are fully processed. See [`Flush`](#flush).

```q
q).kafka.OutQLen producer
5i
```

### `Flush`

_Wait until all outstanding produce requests, et.al, are completed_

```q
.kafka.Flush[prid;timeout]
```

Where 

-   `prid` is the integer value of the producer (integer)
-   `timeout` is the timeout in milliseconds (short/integer/long)

returns a null if all events completed.

This should typically be done prior to destroying a producer instance to make sure all queued and in-flight produce requests are completed before terminating. This function may trigger callbacks.

The `linger.ms` time will be ignored for the duration of the call, queued messages will be sent to the broker as soon as possible.

Relates to []`OutQLen`](#outqlen).

## Subscriptions


> :warning: **Mixing Manual and Dynamic Assignments**
>
> It isn't possible to mix manual partition assignment (i.e. using assign) with dynamic partition assignment through topic subscription


### Dynamic

Used when subscribing to the topics we were interested in and let Kafka dynamically assign a fair share of the partitions for those topics based on the active consumers in the group.

Membership in a consumer group is maintained dynamically: if a process fails, the partitions assigned to it will be reassigned to other consumers in the same group.

The subscribe method is not incremental: you must include the full list of topics that you want to consume from.

> :note: **Rebalance**
>
> A rebalance operation occurs if any one of the following events are triggered:
>
> -   Number of partitions change for any of the subscribed topics
> -   A subscribed topic is created or deleted
> -   An existing member of the consumer group is shutdown or fails
> -   A new member is added to the consumer group
>
> Group rebalances will cause partition offsets to be reset (e.g. application of auto.offset.reset setting) 

#### `Sub`

_High level subscription from a consumer process to a topic_

```q
.kafka.Sub[clid;topic;partid]
```

Where

-   `clid` is the client ID (integer)
-   `topic` is the topic/s being subscribed to (symbol atom – or list, for v1.6+)
-   `partid` is the target partition (enlisted integer) (UNUSED)

returns a null on successful execution. Received msgs are then consumed via a call to the registered [`consumetopic`](#consumetopic)) function.

The full topic list is retrieved every `topic.metadata.refresh.interval.ms` to pick up new or delete topics that match the subscription. If there is any change to the matched topics the consumer will immediately rejoin the group with the updated set of subscribed topics.

This is an asynchronous method which returns immediately: background threads will (re)join the group, wait for group rebalance, assign() the assigned partitions, and then start fetching messages. This cycle may take up to `session.timeout.ms` * 2 or more to complete.

The msg callback (defaults to [`consumetopic`](#consumetopic)) can return a consumer error UNKNOWN_TOPIC_OR_PART for non-existent topics, and TOPIC_AUTHORIZATION_FAILED for unauthorized topics e.g.
```q
mtype                 topic client partition offset msgtime                       data                                                                        key      headers                 rcvtime                      
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UNKNOWN_TOPIC_OR_PART test1 0      0         -1001                                "Subscribed topic not available: test1: Broker: Unknown topic or partition" `byte$() (`symbol$())!`symbol$() 2024.04.23D14:04:03.584293000
``` 

**Subscribing in advance**
Subscriptions can be made to topics that do not currently exist.

**Multiple subscriptions** 
As of v1.4.0 multiple calls to `.kafka.Sub` for a given client will allow for consumption from multiple topics rather than overwriting the subscribed topic, although each addition will cause a rebalance.

> :warning: **Partition ID**
> 
> The parameter `partid` is a legacy argument to the function and with recent versions of librdkafka does not have any effect on the subscription. On subscription Kafka handles organisation of consumers based on the active members of a `group.id` to efficiently distribute consumption amongst the group.

```q
q)client:.kafka.Consumer[kfk_cfg]
q).kafka.PARTITION_UA // subscription defined to be to an unassigned partition
-1i
// List of topics to be subscribed to
q).kafka.Sub[client;(topic1;topic2);enlist .kafka.PARTITION_UA]
```

#### `Subscribe`

_Subscribe from a consumer to a topic with a specified callback_

```q
.kafka.Subscribe[clid;topic;partid;callback]
```

Where

-   `clid` is the client ID (integer)
-   `topic` is the topic/s being subscribed to (symbol atom – or list, for v1.6+)
-   `partid` is the target partition (enlisted integer) (UNUSED)
-   `callback` is a callback function defined related to the subscribed topic. This function should take as input a single parameter, 
    the content of a message received from any calls to the subscription on the topic.

returns a null on successful execution. As per [`Sub`](#sub) but augments `.kafka.consumetopic` with a new callback function for the consumer.

> :warning: **Partition ID**
> 
> The parameter `partid` is a legacy argument to the function and with recent versions of librdkafka does not have any effect on the subscription. On subscription Kafka handles organization of consumers based on the active members of a `group.id` to efficiently distribute consumption among the group.

```q
q)// create a client with a user created config kfk_cfg
q)client:.kafka.Consumer kfk_cfg
q)// Subscription consumes from any available partition
q)part:.kafka.PARTITION_UA 
q)// List of topics to be subscribed to
q)topicname:`test
q)// Display consumer callbacks prior to new subscription
q).kafka.consumetopic
     | {[msg]}
q).kafka.Subscribe[client;topicname;enlist part;{[msg]show msg;}]
q)// Display consumer callbacks following invocation of Subscribe
q).kafka.consumetopic
    | {[msg]}
test| {[msg]show msg;}
```

> **Consume callbacks**
>     
> The addition of callbacks specific to a topic was added in `v1.5.0` a call of `.kafka.Subscribe` augments the dictionary `.kafka.consumetopic` where the key maps topic name to the callback function in question. A check for a custom callback is made on each call to `.kafka.consumecb` following `v1.5.0`. If an appropriate key is found the associated callback will be invoked. The default callback can be modified via modification of ```.kafka.consumetopic[`]```

#### `Subscription`

_Most-recent subscription to a topic_

```q
.kafka.Subscription clid
```

Where `clid` is the client ID (integer) which the subscription is being requested for, 
returns a table with the topic, partition, offset and metadata of the most recent subscription.

```q
q)client:.kafka.Consumer kfk_cfg
q).kafka.Sub[client;`test2;enlist -1i]
q).kafka.Subscription client
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

```q
.kafka.Assign[clid;tpc_part]
```

Where

-   `clid` is an integer denoting the client ID which the assignment is to applied
-   `tpc_part` is a dictionary mapping topic names (symbol) to partitions (long), or from v.1.6 onwards a Symbol!Dictionary mapping of topic to partitions/offset (dictionary mapping of integer partition to long offset location)

returns a null on successful execution. Received msgs are then consumed via a call to the registered [`consumetopic`](#consumetopic)) function.

```q
// subscribe to test (partition 0) and test1 (partition 1)
.kafka.Assign[cid;`test`test1!0 1]

// subscribe to test1 (partition 0 from offset 10) and test2 
// (partition 0 from offset 10)
.kafka.Assign[client;`test1`test2!(((1#0i)!1#10);((1#0i)!1#10))]
```

#### `AssignOffsets`

_Assign partitions to be consumed._

```q
.kafka.AssignOffsets[clid;topic;part_offsets]
```

Where

-   `clid` is the consumer ID (integer)
-   `topic` is the topic (symbol)
-   `part_offsets` is a dictionary of partitions and where to start consuming them

returns a null on successful execution. Received msgs are then consumed via a call to the registered [`consumetopic`](#consumetopic)) function.

If previous assignments for a different topic/partition have already been communicated to the Kafka infrastructure, these assignments will be reapplied.

> From v1.6, [`.kafka.Assign`](#assign) is preferred for assigning multiple offsets/topics.

```q
q).kafka.OFFSET.END   // start consumption at end of partition
-1
q).kafka.OFFSET.BEGINNING // start consumption at start of partition
-2
q).kafka.AssignOffsets[client;TOPIC;(1#0i)!1#.kafka.OFFSET.END]
```

> **Last-committed offset**
> 
> In the above examples an offset of .kafka.OFFSET.INVALID (-1001) is a special value. 
> It indicates the offset could not be determined and the consumer will read from the last-committed offset once one becomes available.

#### `AssignAdd`

_Add additional topic-partition pairs to the current assignment._

```q
.kafka.Assign[clid;tpc_part]
```

Where

-   `clid` is the client ID (integer)
-   `tpc_part` is a dictionary mapping topic names (symbol) to partitions (long), to be added to the current assignment

returns a null on successful execution; will display inappropriate assignments if necessary

> From v1.6, [`.kafka.Assign`](#assign) is preferred for assigning multiple offsets/topics.

If previous assignments have already been communicated to the Kafka infrastructure, these assignments will be reapplied.

```q
q)// Create a new assignment
q).kafka.Assign[cid;`test`test1!0 0]

q)// Retrieve the current assignment
q).kafka.Assignment[cid]
topic partition offset metadata
-------------------------------
test1 0         -1001  ""      
test2 0         -1001  ""      

q)// Add new assignments to the current assignment
q).kafka.AssignAdd[cid;`test`test1!1 1]

q)// Retrieve the current assignment
q).kafka.Assignment[cid]
topic partition offset metadata
-------------------------------
test  1         -1001  ""      
test1 0         -1001  ""      
test1 1         -1001  ""      
test2 0         -1001  ""      

q)// Attempt to assign an already assigned topic partition pair
q).kafka.AssignAdd[cid;`test`test1!1 1]
`test  1
`test1 1
'The above topic-partition pairs already exist, please modify dictionary
```

#### `AssignDel`

_Delete a set of topic-partition pairs from the current assignment._

```q
.kafka.AssignDel[clid;tpc_part]
```

Where

-   `clid` is a client ID (integer) 
-   `tpc_part` is a dictionary mapping topic names (symbol) to partitions (long)

removes the topic-partition pairs and returns a null; will display inappropriate assignment deletion if necessary.

> From v1.6, [`.kafka.Assign`](#assign) is preferred for assigning multiple offsets/topics.

If previous assignments have already been communicated to the Kafka infrastructure, these remaining assignments will be reapplied

```q
q)// Create a new assignment
q).kafka.Assign[cid;`test`test`test1`test1!0 1 0 1]

q)// Retrieve the current assignment
q).kafka.Assignment[cid]
topic partition offset metadata
-------------------------------
test  0         -1001  ""
test  1         -1001  ""
test1 0         -1001  ""
test1 1         -1001  ""

q)// Add new assignments to the current assignment
q).kafka.AssignDel[cid;`test`test1!1 1]

q)// Retrieve the current assignment
q).kafka.Assignment[cid]
topic partition offset metadata
-------------------------------
test  0         -1001  ""
test1 0         -1001  ""

q)// Attempt to assign an already unassigned topic partition pair
q).kafka.AssignDel[cid;`test`test1!1 1]
`test  1
`test1 1
'The above topic-partition pairs cannot be deleted as they are not assigned
```

#### `Assignment`

_Retrieve the current assignment for a specified client_

```q
.kafka.Assignment clid
```

Where `clid` is a client ID, returns a list of dictionaries describing the current assignment for it.

```q
q)// Attempt to retrieve assignment without a current assignment
q).kafka.Assignment cid 
topic partition offset metadata
-------------------------------

q)// Create a new assignment
q).kafka.Assign[cid;`test`test1!0 1]

q)// Retrieve the new current assignment
q).kafka.Assignment[cid]
topic partition offset metadata
-------------------------------
test  0         -1001  ""
test1 1         -1001  ""
```

### General Subscription Functions

#### `Unsub`

_Unsubscribe from all topics associated with Client regardless of whether created via manual or dynamic assigned subscriptions_

```q
.kafka.Unsub clid
```

Where `clid` is a client ID (integer), unsubscribes it from all topics and returns a null; signals an error if client is unknown.

```q
q).kafka.Unsub[0i]
q).kafka.Unsub[1i]
'unknown client
```

### Polling

#### `MaxMsgsPerPoll`

_Set the maximum number of messages per poll_

```q
.kafka.MaxMsgsPerPoll max_messages
```

Where `max_messages` is the maximum number of messages (integer) per poll returns the set limit.

```q
q).kafka.MaxMsgsPerPoll 100
100
```

> **Upper limit set by `.kafka.MaxMsgsPerPoll` vs max_messages in `.kafka.Poll`**
> 
> The argument `max_messages` passed to `.kafka.Poll` is preferred to the global limit of maximum number of messages set by `.kafka.MaxMsgPerPoll`. 
> The latter limit is used only when `max_messages` passed to `.kafka.Poll` is 0.

#### `Poll`

_Manually poll the messages from the message feed_

```q
.kafka.Poll[cid;timeout;max_messages]
```

Where

-   `cid` is a client ID (integer)
-   `timeout` is max time in ms to block the process (long)
-   `max_messages` is the max number of messages to be polled (long)

returns the number of messages polled within the allotted time.

```q
q).kafka.Poll[0i;5;100]
0
q).kafka.Poll[0i;100;100]
10
```


