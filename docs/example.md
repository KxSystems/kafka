# kdb+ Kafka Example

Follow the [installation instructions](install.md) for set-up.

To run examples on this page you will need a Kafka broker available. In these examples we use the kafka module with `.kafka`

## API Introduction

The library follows the `librdkafka` API closely where possible.
As per its [introduction](https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md):

-   Base container `rd_kafka_t` is a client created by `.kafka.Client`. For ease of use `.kafka.Producer` and `.kafka.Consumer` are provided. These provide global configuration and shared states.
-   One or more topics `rd_kafka_topic_t`, which are either producers or consumers are created by the function `.kafka.Topic` 

Both clients and topics accept an optional configuration dictionary.
`.kafka.Client` and `.kafka.Topic` return an int which acts as a Client or Topic ID (index into an internal array). Client IDs are used to create topics and Topic IDs are used to publish or subscribe to data on that topic. They can also be used to query metadata – state of subscription, pending queues, etc.

### Minimal producer example

```q
.kafka:use`kafka
// specify kafka brokers to connect to and statistics settings.
kfk_cfg:`metadata.broker.list`statistics.interval.ms!`localhost:9092`10000
// create producer with the config above
producer:.kafka.Producer[kfk_cfg]
// setup producer topic "test"
test_topic:.kafka.Topic[producer;`test;()!()]
// publish current time with a key "time"
.kafka.Pub[test_topic;.kafka.PARTITION_UA;string .z.t;"time"];
show "Published 1 message";
```

:point_right: 
[KxSystems/kafka/examples/test_producer.q](https://github.com/KxSystems/kafka/blob/master/examples/test_producer.q)

### Minimal consumer example

```q
.kafka:use`kafka
// create consumer process within group 0
client:.kafka.Consumer[`metadata.broker.list`group.id!`localhost:9092`0];
data:();
// setup meaningful consumer callback(do nothing by default)
.kafka.SetConsumeCb[{[msg]
    msg[`data]:"c"$msg[`data];
    msg[`rcvtime]:.z.p;
    data,:enlist msg;}]
// subscribe to the "test" topic with default partitioning
.kafka.Sub[client;`test;enlist .kafka.PARTITION_UA];
```

:point_right: 
[KxSystems/kafka/examples/test_consumer.q](https://github.com/KxSystems/kafka/blob/master/examples/test_consumer.q) for a slightly more elaborate version 

## Test Environment

One can use either existing Kafka broker or start a test Kafka broker as described below.

### Setting up a test Kafka instance

To start a Kafka instance for testing follow the instructions outlined in the link below

:point_right: 
[Apache Kafka tutorial](http://kafka.apache.org/documentation.html#quickstart)

Kafka is initialized using the following commands. 

Generate a Cluster UUID

```bash
KAFKA_CLUSTER_ID="$(bin/kafka-storage.sh random-uuid)"
```

Format Log Directories

```bash
bin/kafka-storage.sh format --standalone -t $KAFKA_CLUSTER_ID -c config/server.properties
```

Start Kafka broker.

```bash
bin/kafka-server-start.sh config/server.properties
```

### Running examples

#### Finance

##### Step 1
1. Ensure a kafka broker is running on `localhost:9092`
1. Ensure that the `kafka`, `log` and `printf` modules are in your `$QPATH`. For more information on this search path see [here](https://code.kx.com/kdb-x/modules/module-framework/quickstart.html#search-path).

##### Step 2

Start the application

1. Start a producer

This will publish to two topics, trade and quote, on a timer

```bash
$HOME/.kx/bin/q examples/finance/feed.q -init 1
```

1. Start a consumer

This will subscribe to a topic which is set at the command line. If the topic is trade, then a position table will be maintained.
If you want to print out the count of messages received, add a stats argument to the command line.

```bash
$HOME/.kx/bin/q examples/finance/sub.q -topic trade -init 1 -stats 30000
```

```q
2025.11.21D15:03:48.151078693 info PID[1216323] HOST[lptp1234] Subscribed to topic: trade
q)2025.11.21D15:03:48.151314031 info PID[1216323] HOST[lptp1234] {"quote":0,"trade":0}
q)2025.11.21D15:04:18.151560405 info PID[1216323] HOST[lptp1234] {"quote":0,"trade":4}
```

#### Basic

Start producer.

```q
q)\l test_producer.q
"Publishing on topic:test"
"Published 1 message"
topic              err     partitions                                        ..
-----------------------------------------------------------------------------..
test               Success ,`id`err`leader`replicas`isrs!(0i;`Success;0i;,0i;..
__consumer_offsets Success (`id`err`leader`replicas`isrs!(0i;`Success;0i;,0i;..
"Set timer with \t 1000 to publish message every second"
q)\t 1000
```

Start consumer.

```q
q)\l test_consumer.q
q)data
mtype topic client partition offset msgtime                       data       ..
-----------------------------------------------------------------------------..
      test  0      0         20616  2019.08.09D09:11:03.709000000 "2019.08.09..
      test  0      0         20617  2019.08.09D09:11:21.955000000 "2019.08.09..
      test  0      0         20618  2019.08.09D09:11:22.956000000 "2019.08.09..
      test  0      0         20619  2019.08.09D09:11:23.955000000 "2019.08.09..
      test  0      0         20620  2019.08.09D09:11:24.956000000 "2019.08.09..
      test  0      0         20621  2019.08.09D09:11:25.956000000 "2019.08.09..
```

The messages will now flow from producer to consumer, the publishing rate can be adjusted via `\t x` in the producer process.

