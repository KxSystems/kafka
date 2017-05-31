# Introduction
`kfk` is a thin wrapper for kdb+ around [librdkadka](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/). 

# API

Library tries to follow `librdkafka` API closely where possible.
Following https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md:
 - Base container(`rd_kafka_t`) is a client create by `.kfk.Client`. `.kfk.Producer` and `.kfk.Consumer` provided for simplicity. Provides global configuration and shared state
 - One or more topics(`rd_kafka_topic_t`) which are either producers or consumers and create by `.kfk.Topic` function

Both clients and topics accept optional configuration dictionary.
 `.kfk.Client` and `.kfk.Topic` returns an `int` which acts as a client or topic id(index into an internal array). Client IDs are used to create topics and Topic IDs are used to publish or subscribe to data on that topic. Additionally, they can be used to query metadata - state of subscription, pending queues, etc.

Minimal producer example(can also be found in test_producer.q)
```q
\l kfk.q
// specify kafka brokers to connect to and statistics settings.
kfk_cfg:`metadata.broker.list`statistics.interval.ms!`localhost:9092`10000
// create producer with the config above
producer:.kfk.Producer[kfk_cfg]
// setup producer topic "test"
test_topic:.kfk.Topic[producer;`test;()!()]
// publish current time with a key "time"
.kfk.Pub[test_topic;.kfk.PARTITION_UA;string .z.t;"time"];
show "Published 1 message";
```
Minimal consumer example(slightly elaborate version in test_consumer.q)
```q
\l kfk.q
// create consumer process within group 0
client:.kfk.Consumer[`metadata.broker.list`group.id!`localhost:9092`0];
data:();
// setup meaningful consumer callback(do nothing by default)
.kfk.consumecb:{[msg]
    msg[`data]:"c"$msg[`data];
    msg[`rcvtime]:.z.p;
    data,::enlist msg;}
// subscribe to the "test" topic with default partitioning
.kfk.Sub[client;`test;enlist .kfk.PARTITION_UA];
```

# Configuration

Library supports and uses all configuration options exposed by `librdkafka` except callback functions. Which are identical to Kafka options by design of `librdkafka`
For list of options see: https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md


# Building and installation

## Step 1
Build and install latest version of librdkafka.
### macOS and Linux
```bash
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
# Note: run `make clean` if updating/installed both 64 bit version before
./configure --prefix=$HOME --disable-sasl --disable-lz4 --mbits=32 

# When using macOS with OpenSSL you might need to set `export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl/1.0.2k` before make
# If not using OpenSSL, add --disable-ssl to configure above
make
make install

// 64 bits
# Note: run `make clean` if updating/installed both 32 bit version before
./configure --prefix=$HOME --disable-sasl --disable-lz4 --mbits=64
# When using macOS with OpenSSL you might need to set `export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl/1.0.2k` before make
# If not using OpenSSL, add --disable-ssl to configure above
make
make install

```
### Windows (to be added)
Using Nuget.
```
nuget install librdkafka.redist
```

## Step 2
Compile and install shared object(it will be installed to $QHOME/<arch>). Make sure you have QHOME environment set.
```bash
// in kfk source folder
make
make install
```


# Testing

Use can use either existing kafka broker or start test kafka broker as described below.

## Setting up test kafka instance

As per tutorial on Kafka website - http://kafka.apache.org/documentation.html#quickstart

Download and unzip kafka
```bash
cd $HOME
wget http://www-us.apache.org/dist/kafka/0.10.2.0/kafka_2.11-0.10.2.0.tgz
tar xzvf kafka_2.11-0.10.2.0.tgz
cd $HOME/kafka_2.11-0.10.2.0
```

Start zookeeper
```bash
bin/zookeeper-server-start.sh config/zookeeper.properties
```

Start kafka broker
```bash
bin/kafka-server-start.sh config/server.properties
```

## Running examples

start producer
```q
\l test_producer.q
\t 1000
```

start consumer
```q
\l test_consumer.q
```
The messages will now flow from producer to consumer and the publishing rate can be adjusted via `\t x` in producer process.

# Performance and Tuning

See https://github.com/edenhill/librdkafka/wiki/How-to-decrease-message-latency for configuration options to reduce kafka latency.
There are numerous configuration options and it is best to find settings that suit your needs and setup. See Configuration section above

