# ![Kafka](docs/kafka.png) `kfk` – Kafka for kdb+

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kxsystems/kafka)](https://github.com/kxsystems/kafka/releases) [![Travis (.org) branch](https://img.shields.io/travis/kxsystems/kafka/master)](https://travis-ci.org/kxsystems/kafka/branches)



`kfk` is a thin wrapper for kdb+ around [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/).
It is part of the [_Fusion for kdb+_](https://code.kx.com/q/interfaces) interface collection.

This interface is supported for the following platforms

* 32- & 64-bit macOS and Linux
* 64-bit Windows

## New to kdb+ ?

Kdb+ is the world’s fastest time-series database, optimized for ingesting, analyzing and storing massive amounts of structured data. To get started with kdb+, see https://code.kx.com/q for downloads and developer information. For general information, visit https://kx.com/

## API Documentation

:point_right: [`API reference`](docs/reference.md)

## Installation Documentation

:point_right: [`Install guide`](docs/install.md)

## Example Setup

:point_right: [`Example setup guide`](docs/example.md)

## Performance and Tuning

:point_right: 
[edenhill/librdkafka/wiki/How-to-decrease-message-latency](https://github.com/edenhill/librdkafka/wiki/How-to-decrease-message-latency)

There are numerous configuration options and it is best to find settings that suit your needs and setup.

## Status

This interface is provided under an Apache 2.0 license.

If you find issues with the interface or have feature requests please [raise an issue](../..//issues).

To contribute to this project, please follow the [contribution guide](CONTRIBUTING.md).