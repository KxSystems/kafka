---
title: Using Kafka with kdb+ – Interfaces
description: How to connect a kdb+ server process to the Apache Kafka distributed streaming platform
keywords: apache, api, consumer, fusion, interface, kafka, learning, library, machine, producer, q
---

# ![Apache Kafka](../img/kafka.png) Using Kafka with kdb+

:fontawesome-brands-github: [KxSystems/kafka](https://github.com/KxSystems/kafka)

`kafkakdb` is a thin wrapper for kdb+ around the `librdkafka` C API (available on [MacOS/Linux](https://github.com/edenhill/librdkafka) or [Windows](https://www.nuget.org/packages/librdkafka.redist/1.0.0)) for [Apache Kafka](https://kafka.apache.org/).

Follow the [installation instructions](https://github.com/KxSystems/kafka#building-and-installation) for set-up.

To run examples on this page you will need a Kafka broker available. It is easy to [set up a local instance for testing](https://github.com/KxSystems/kafka#setting-up-test-kafka-instance).

## API

The library follows the `librdkafka` API closely where possible.
As per its [introduction](https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md):

- Base container `rd_kafka_t` is a client created by `.kafka.newProducer` and `.kafka.newConsumer`. These provide global configuration and shared states.
- One or more topics `rd_kafka_topic_t`, which are either producers or consumers are created by the function `.kafka.newTopic`.

Both clients and topics accept an optional configuration dictionary.
`.kafka.newProducer`, `.kafka.newConsumer` and `.kafka.newTopic` return an int which acts as a Client or Topic ID (index into an internal array). Client IDs are used to create topics and Topic IDs are used to publish or subscribe to data on that topic. They can also be used to query metadata – state of subscription, pending queues, etc.


## Performance and tuning

:fontawesome-regular-hand-point-right: 
[:fontawesome-brands-github: edenhill/librdkafka/wiki/How-to-decrease-message-latency](https://github.com/edenhill/librdkafka/wiki/How-to-decrease-message-latency)

There are numerous configuration options and it is best to find settings that suit your needs and setup. See [Configuration](#configuration) above. 
