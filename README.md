# kdb+ interface for kafka broker

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kxsystems/kafka)](https://github.com/kxsystems/kafka/releases) [![Travis (.org) branch](https://img.shields.io/travis/kxsystems/kafka/master)](https://travis-ci.org/kxsystems/kafka/branches)

## Introduction

`kafkakdb` is a thin wrapper for kdb+ around [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/).
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
$ make install

```

**Notes:** 

1. For 32-bit build changing `-mbits=64` to `-mbits=32`.
2. If using OpenSSL, remove `--disable-ssl` from configure command below
3. On macOS with OpenSSL you might need to set `export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl` before proceeding


#### Windows

##### Install rdkafka

In order to install rdkafka library there are two ways:
1. Use NuGet
2. Use CMake

As written in the [document](https://github.com/edenhill/librdkafka/tree/master/packaging/cmake) of the repository, CMake build is still experimental but with CMake this installation guide becomes much simpler. We give an instruction for CMake build as an alternative method of NuGet install.

**1. Use NuGet**

Install librdkafka and copy relevant directories to new directory `librdkafka`. The environmental variable `KAFKA_INSTALL_DIR` set here is used to build the kdb+ interface.

```bat

> curl -o ./nuget.exe -L https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
> nuget.exe install librdkafka.redist -Version 1.5.3
> mkdir librdkafka
> set KAFKA_INSTALL_DIR=%cd%\librdkafka
> xcopy librdkafka.redist.1.5.3\build\native\include\librdkafka librdkafka\include\
> xcopy librdkafka.redist.1.5.3\build\native\lib\win\x64\win-x64-Release\v120 librdkafka\lib\
> xcopy librdkafka.redist.1.5.3\runtimes\win-x64\native librdkafka\bin\

```

Create a symlink to the `librdkafka.dll`, `zlib.dll` and `libzstd.dll` under `%QHOME%\w64`.

```bat

> cd %QHOME%\w64
w64> MKLINK librdkafka.dll %KAFKA_INSTALL_DIR%\bin\librdkafka.dll
w64> MKLINK zlib.dll %KAFKA_INSTALL_DIR%\bin\zlib.dll
w64> MKLINK libzstd.dll %KAFKA_INSTALL_DIR%\bin\libzstd.dll

```

**2. Use CMake**

First we need to install zlib. Download zlib from the official homepage (https://www.zlib.net/) and build with CMake.

```bat

> curl -L https://www.zlib.net/zlib1211.zip -o zlib1211.zip
> 7z x zlib1211.zip
> ren zlib-1.2.11 zlib
> cd zlib
zlib> mkdir build
zlib> mkdir install
zlib> cd build
build> cmake --config Release -DCMAKE_INSTALL_PREFIX=..\install ..
build> cmake --build . --config Release --target install

```

Create a symlink to the `zlib.dll` under `%QHOME%\w64`.

```bat

build> cd %QHOME%\w64
w64> MKLINK zlib.dll %KAFKA_INSTALL_DIR%\bin\zlib.dll

```

Clone the source repository and build with CMake. The environmental variable `KAFKA_INSTALL_DIR` set here is used to build the kdb+ interface.

```bat

> git clone https://github.com/edenhill/librdkafka.git
> cd librdkafka
librdkafka> mkdir install
librdkafka> set KAFKA_INSTALL_DIR=%cd%\install
librdkafka> mkdir build
librdkafka> cd build
build> cmake --config Release -DCMAKE_INSTALL_PREFIX=%KAFKA_INSTALL_DIR% .. -DRDKAFKA_BUILD_TESTS:BOOL=OFF -DRDKAFKA_BUILD_EXAMPLES:BOOL=OFF -DWITH_SASL:BOOL=OFF -DENABLE_LZ4_EXT:BOOL=OFF -DWITH_BUNDLED_SSL:BOOL=OFF
build> cmake --build . --config Release --target install

```

**Note:** If you use SSL, remove the flag `-DWITH_BUNDLED_SSL:BOOL=OFF`.

**Mess Up for Successful Install:** 🤷🤷🤷

Somehow `librdkafka.lib` is required even when `rdkafka.lib` was successfully found by CMake though name `librdkafka.lib` does not exist in the generated project file... We need to rename the `rdkafka.lib` to `librdkafka.lib`.

```bat

build> cd ..\install\lib
lib> rename rdkafka.lib librdkafka.lib

```

Create a symlink to the `rdkafka.dll` under `%QHOME%\w64`.

```bat

build> cd %QHOME%\w64
w64> MKLINK rdkafka.dll %KAFKA_INSTALL_DIR%\bin\rdkafka.dll

```

### Install kafkakdb

To use OpenSSL set `OPENSSL_ROOT_DIR` to the install directory of OpenSSL.

#### Linux/MacOSX

```bash

]$ git clone https://github.com/KxSystems/kafka.git
]$ cd kafka
]$ mkdir build && cd build
build]$ cmake .. -DENABLE_SSL:BOOL=OFF
build]$ cmake --build . --target install

```

**Notes:**
1. `cmake --build . --target install` as used in the Linux/MacOS builds installs the required share object and q files to the `QHOME/[ml]64` and `QHOME` directories respectively. If you do not wish to install these files directly, you can execute `cmake --build .` instead of `cmake --build . --target install` and move the files from their build location at `build/kafkakdb`.
2. If you use TLS remove the flag `-DENABLE_SSL:BOOL=OFF`.

#### Windows

```bat

> git clone https://github.com/KxSystems/kafka.git
> cd kafka
> mkdir build && cd build
build> cmake --config Release .. -DENABLE_SSL:BOOL=OFF
build> cmake --build . --config Release --target install

```

**Notes:**

1. `cmake --build . --config Release --target install` installs the required share object and q files to the `QHOME\w64` and `QHOME` directories respectively. If you do not wish to install these files directly, you can execute `cmake --build . --config Release` instead of `cmake --build . --config Release --target install` and move the files from their build location at `build/kafkakdb`.
2. You can use flag `cmake -G "Visual Studio 16 2019" -A Win32` if building 32-bit version.
3. If you use TLS remove the flag `-DENABLE_SSL:BOOL=OFF`.

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
