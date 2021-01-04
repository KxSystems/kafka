# `kfk` – Kafka for kdb+

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kxsystems/kafka)](https://github.com/kxsystems/kafka/releases) [![Travis (.org) branch](https://img.shields.io/travis/kxsystems/kafka/master)](https://travis-ci.org/kxsystems/kafka/branches)

## Introduction

`kfk` is a thin wrapper for kdb+ around [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/).
It is part of the [_Fusion for kdb+_](https://code.kx.com/v2/interfaces/fusion/) interface collection.

This interface is supported for the following platforms

* 32 & 64 bit MacOS and Linux
* 64 bit Windows

## New to kdb+?

kdb+ is the world's fastest time-series database, optimized for ingesting, analyzing and storing massive amounts of structured data. To get started with kdb+, please visit https://code.kx.com/q/learn/ for downloads and developer information. For general information, visit https://kx.com/

## New to Kafka?

Apache Kafka is an open-source distributed event streaming platform. For detail you can check [the official page](https://kafka.apache.org/).

## Installation

### Requirements

- kdb+ >= 3.5 64-bit (Linux/MacOS/Windows)
- [Kafka C API](https://github.com/edenhill/librdkafka/tree/master/src) >= 0.11.0
- CMake >= 3.1 [^1]

[^1]: Required when building from source

### Third-Party Library Installation

#### Linux & Mac

There are two ways to install `librdkafka`, installing pre-built binary or building from source.

##### 1. Using Package Manager

- macOS
  
        $ brew install librdkafka

- Ubuntu/Debian (unstable)

        $ sudo apt-get install librdkafka-dev

- RHEL/CentOS

        $ sudo yum install librdkafka-devel

Set `KAFKA_INSTALL_DIR` to the install direcotry where `include` and `lib` exist. This environmental variabe is used to build the kdb+ interface.

Then add the path to `LD_LIBRARY_PATH` (Linux) or `DYLD_LIBRRAY_PATH` (MacOSX) appending `/lib` so that kdb+ can refer to Kafka library at runtime, i.e.:

```bash

# Linux
$ export LD_LIBRARY_PATH=${KAFKA_LINSTALL_DIR}/lib:${LD_LIBRARY_PATH}
# MacOSX
$ export DYLD_LIBRARY_PATH=${KAFKA_LINSTALL_DIR}/lib:${DYLD_LIBRARY_PATH}

```

##### 2. Build from Source

Follow [requirements for `librdkafka` compilation](https://github.com/edenhill/librdkafka#requirements).

**(Extra step for 32-bit Installation)**

To build 32-bit versions on 64-bit OS you need 32-bit versions of libraries and a toolchain.

```shell

#CentOS/RHEL
$ sudo yum install glibc-devel.i686 libgcc.i686 libstdc++.i686 zlib-devel.i686
# Ubuntu
$ sudo apt-get install gcc-multilib

```

Clone the source repository and install by following commands. The environmental variable `KAFKA_INSTALL_DIR` set here is used to build the kdb+ interface.

```bash

$ git clone https://github.com/edenhill/librdkafka.git
$ cd librdkafka
$ mkdir install
$ export KAFKA_INSTALL_DIR=$(pwd)/install

```

Execute `configure` passing the `${KAFKA_INSTALL_DIR}` as a target install direcrtory.

```bash

$ ./configure --prefix=${KAFKA_INSTALL_DIR} --disable-sasl --disable-lz4 --disable-ssl --mbits=64
$ make
$make install

```

**Notes:** 

1. For 32-bit build changing `-mbits=64` to `-mbits=32`.
2. If using OpenSSL, remove `--disable-ssl` from configure command below
3. On macOS with OpenSSL you might need to set `export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl/1.0.2k` before proceeding


#### Windows

For Windows easiest way might be to using CMake. As written in the [document](https://github.com/edenhill/librdkafka/tree/master/packaging/cmake) of the repository, CMake build is still experimental but with CMake this installation guide becomes much simpler.

Clone the source repository and build with CMake. The environmental variable `KAFKA_INSTALL_DIR` set here is used to build the kdb+ interface.

```bat

> git clone https://github.com/edenhill/librdkafka.git
> cd librdkafka
librdkafka> mkdir install
librdkafka> set KAFKA_INSTALL_DIR=%cd%\install
librdkafka> mkdir build
librdkafka> cd build
build> cmake --config Release -DCMAKE_INSTALL_PREFIX=../install .. -DRDKAFKA_BUILD_TESTS:BOOL=OFF -DRDKAFKA_BUILD_EXAMPLES:BOOL=OFF -DWITH_SASL:BOOL=OFF -DENABLE_LZ4_EXT:BOOL=OFF -DWITH_BUNDLED_SSL:BOOL=OFF
build> cmake --build . --config Release --target install

```

**Note:** If you use SSL, remove the flag `-DWITH_BUNDLED_SSL:BOOL=OFF`.

Create a symlink to the `rdkafka.dll` under `%QHOME%\w64`.

```bat

build> cd %QHOME%\w64
w64> MKLINK rdkafka.dll %KAFKA_INSTALL_DIR%\bin\rdkafka.dll

```

### Install kafkakdb

#### Linux/MacOSX

```bash

]$ git clone https://github.com/KxSystems/kafka.git
]$ cd kafka
]$ mkdir build && cd build
build]$ cmake ..
build]$ cmake --build . --target install

```

**Note:** `cmake --build . --target install` as used in the Linux/MacOS builds installs the required share object and q files to the `QHOME/[ml]64` and `QHOME` directories respectively. If you do not wish to install these files directly, you can execute `cmake --build .` instead of `cmake --build . --target install` and move the files from their build location at `build/kafkakdb`.

#### Windows

```bat

> git clone https://github.com/KxSystems/kafka.git
> cd kafka
> mkdir build && cd build
build> cmake --config Release ..
build> cmake --build . --config Release --target install

```

**Notes:**

1. `cmake --build . --config Release --target install` installs the required share object and q files to the `QHOME\w64` and `QHOME` directories respectively. If you do not wish to install these files directly, you can execute `cmake --build . --config Release` instead of `cmake --build . --config Release --target install` and move the files from their build location at `build/kafkakdb`.
2. You can use flag `cmake -G "Visual Studio 16 2019" -A Win32` if building 32-bit version.

## Quick Start

### Requirements

- [Apach Kafka](http://kafka.apache.org/)


If you have not had Apach Kafka broker, download from [here](https://www.apache.org/dyn/closer.cgi?path=/kafka/2.7.0/kafka_2.13-2.7.0.tgz) and extract in your preferable place.

#### Start Kafka Broker

We just follow the [quick-start instruction](http://kafka.apache.org/quickstart) of the official page.

```bash

]$ tar -xzf kafka_2.13-2.7.0.tgz
]$ cd kafka_2.13-2.7.0
# Start the ZooKeeper service
kafka_2.13-2.7.0]$ bin/zookeeper-server-start.sh config/zookeeper.properties

```

In another terminal execute:

```bash

# Start the Kafka broker service
kafka_2.13-2.7.0]$ bin/kafka-server-start.sh config/server.properties

```

#### Launch Consumer

We assume you are in the kdb+ interface source directory.

```bash

kafka]$ cd q
q]$ q ../examples/test_consumer.q

```

#### Launch Producer

```bash

kafka]$ cd q
q]$ q ../examples/test_producer.q

```

## Documentation

Documentation outlining the functionality available for this interface can be found [here](https://code.kx.com/v2/interfaces/kafka/).

## Status

This interface is provided here under an Apache 2.0 license.

If you find issues with the interface or have feature requests please consider raising an issue [here](https://github.com/KxSystems/kafka/issues).

If you wish to contribute to this project please follow the contributing guide [here](CONTRIBUTING.md).
