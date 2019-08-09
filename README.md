# `kfk` – Kafka for kdb+




`kfk` is a thin wrapper for kdb+ around [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/). 
It is part of the [_Fusion for kdb+_](https://code.kx.com/v2/interfaces/fusion/) interface collection.

Please [report issues](https://github.com/KxSystems/kafka/issues) in this repository.

See [code.kx.com/v2/interfaces/kafka](https://code.kx.com/v2/interfaces/kafka/) for full documentation.


## Step 1

Build or install the latest version of `librdkafka`. The minimum required version is v0.11.0.


### Install

_macOS_

```bash
brew install librdkafka
```

_Ubuntu/Debian (unstable)_

```bash
sudo apt-get install librdkafka-dev
```

_RHEL/CentOS_

```bash
sudo yum install librdkafka-devel
```


### Build from source 

Follow [requirements for `librdkafka` compilation](https://github.com/edenhill/librdkafka#requirements).

To build 32-bit versions on 64-bit OS you need 32-bit versions of libraries and a toolchain.

```bash
#CentOS/RHEL
sudo yum install glibc-devel.i686 libgcc.i686 libstdc++.i686 zlib-devel.i686
# Ubuntu
sudo apt-get install gcc-multilib
```


_macOS and Linux_

```bash
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
make clean  # to make sure nothing left from previous build or if upgrading/rebuilding
# If using OpenSSL, remove --disable-ssl from configure command below
# On macOS with OpenSSL you might need to set `export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl/1.0.2k` before proceeding


# 32 bit
./configure --prefix=$HOME --disable-sasl --disable-lz4 --disable-ssl --mbits=32 
# 64 bits
./configure --prefix=$HOME --disable-sasl --disable-lz4 --disable-ssl --mbits=64

make
make install
```


## Step 2

Compile and install a shared object (it will be installed to `$QHOME/<arch>`). Make sure you have `QHOME` set in your environment.

```bash
// in kfk source folder
make
make install
```

Note: If compiling dynamically linked `libkfk.so` make sure you have `librdkafka.so.1` in your `LD_LIBRARY_PATH`.

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/lib
```


## Documentation

See [code.kx.com/v2/interfaces/kafka](https://code.kx.com/v2/interfaces/kafka/).


https://docs.confluent.io/2.0.0/clients/consumer.html#synchronous-commits

To have `launchd` start kafka now, and restart at login:

```bash
brew services start kafka
```

Or, if you don’t want or need a background service you can just run:

```bash
zookeeper-server-start /usr/local/etc/kafka/zookeeper.properties & kafka-server-start /usr/local/etc/kafka/server.properties
```


