# `kfk` – Kafka for kdb+

`kfk` is a thin wrapper for kdb+ around [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/).
It is part of the [_Fusion for kdb+_](http://code.kx.com/v2/interfaces/fusion/) interface collection.

Please [report issues](https://github.com/KxSystems/kafka/issues) in this repository.

See [code.kx.com/v2/interfaces/kafka](http://code.kx.com/v2/interfaces/kafka/) for full documentation.

This interface is supported for the following platforms

* 32 & 64 bit MacOS and Linux
* 64 bit Windows

The following sections outline the instructions for building from source the linux, macOS and Windows builds the kafka interface for kdb+.

## Linux & Mac

### Step 1

Build or install the latest version of `librdkafka`. The minimum required version is v0.11.0.


#### Install

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


#### Build from source 

Follow [requirements for `librdkafka` compilation](https://github.com/edenhill/librdkafka#requirements).

To build 32-bit versions on 64-bit OS you need 32-bit versions of libraries and a toolchain.

```bash
#CentOS/RHEL
sudo yum install glibc-devel.i686 libgcc.i686 libstdc++.i686 zlib-devel.i686
# Ubuntu
sudo apt-get install gcc-multilib
```

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


### Step 2

Compile, install and move shared object file to appropriate location.

1. Make sure you have `QHOME` set as an environment variable.

2. Run the following set of commands to set up the system as outlined

```bash
// in kfk source folder
make
// move installed `.so` to `$QHOME/<arch>`
make install
// remove `.so` from kfk source folder
make clean
```

Note: If compiling dynamically linked `libkfk.so` make sure you have `librdkafka.so.1` in your `LD_LIBRARY_PATH`.

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/lib
```

## Windows
At present the windows compile of the shared object file for the kafka interface uses `Visual Studio 2017` to complete compile. The following steps must be followed to complete this

1. Install nuget for Windows: https:/nuget.com/downloads

2. Install the redistributed version of librdkafka which is suitable for use with windows, documentation can be found [here](https://www.nuget.org/packages/librdkafka.redist/1.0.0)

        >nuget install librdkafka.redist

3. Ensure that you have Windows Visual Studio 2017 installed.

4. Place the installed librdkafka.redist into an appropriate location (suggestions `%HOME%` or `%QHOME%`).
   For the remaining instructions the path to the install for this example is "C:/Users/jdoe/librdkafka.redist.1.0.0"

5. Update LIB user environment variable to include the following path to rdkafka.h for appropriate Windows architecture in this case

        - LIB = C:/Users/jdoe/librdkafka.redist.1.0.0/build/native/lib/win/x64/win-x64-Release/v120

6. Update PATH system environment variable to include path to native folder for appropriate computer architecture

        - PATH = C:/Users/jdoe/librdkafka.redist.1.0.0/runtimes/win-x64/native

7. Create a user environment variable `KAFKA_NATIVE` in line with the following example path (If not set a user will be prompted to do so at build time)

        - KAFKA_NATIVE = C:/Users/jdoe/librdkafka.redist.1.0.0/build/native/include/

8. Clone the kafka interface from the KxSystems github

        >git clone https://github.com/kxsystems/kafka

9. Move to the `kafka/build/` folder within the github clone and run the following;

        >call "build.bat"

10. Follow the prompts outlined by the install file
11. Move the created `.dll` from the build folder to `%QHOME%/<arch>`

## Documentation

See [code.kx.com/v2/interfaces/kafka](http://code.kx.com/v2/interfaces/kafka/).


https://docs.confluent.io/2.0.0/clients/consumer.html#synchronous-commits

To have `launched` start kafka now, and restart at login:

```bash
brew services start kafka
```

Or, if you don’t want or need a background service you can just run:

```bash
zookeeper-server-start /usr/local/etc/kafka/zookeeper.properties & kafka-server-start /usr/local/etc/kafka/server.properties
```
