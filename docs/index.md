---
title: Using Kafka with kdb+ – Interfaces
description: How to connect a kdb+ server process to the Apache Kafka distributed streaming platform
keywords: fusion, interface, kafka, library, q, kdb+, schema registry
---

# ![Apache Kafka](../img/kafka.png) Using Kafka with kdb+

:fontawesome-brands-github: [KxSystems/kafka](https://github.com/KxSystems/kafka)

`kafkakdb` is using the `librdkafka` C API (available on [MacOS/Linux](https://github.com/edenhill/librdkafka) or [Windows](https://www.nuget.org/packages/librdkafka.redist/1.0.0)) for [Apache Kafka](https://kafka.apache.org/).

## Installaton

- Install librdkafka: Follow [the instruction](https://github.com/KxSystems/kafka#third-party-library-installation) in README.
- Install kafkakdb: Follow [the instruction](https://github.com/KxSystems/kafka#install-kafkakdb) in README.

## Confluent Schema Registry

From kafkakdb 2.0, Confluent Kafka Schema Registry is supported. You can interact with the schema registry with a simple q functions. For example, if you need to query a schem contents and schema ID, you can query like below:

```q
q)schemaInfo: .kafka.getSchemaInfoByTopic[`localhost; 8081; `test1; `latest];
```

Then you can use the schema information to build a pipeline which is used to serialize/deserialize messages between q and shchema-registry format.

```q
q)pipeline_name: `$string schemaInfo `id;
q).qtfm.createNewPipeline[pipeline_name];
.. To be continued ..
```

For more detail, see [Schema Registry](#schema_registry.md) page.

## Performance and tuning

:fontawesome-regular-hand-point-right: 
[:fontawesome-brands-github: edenhill/librdkafka/wiki/How-to-decrease-message-latency](https://github.com/edenhill/librdkafka/wiki/How-to-decrease-message-latency)
