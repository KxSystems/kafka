# ![Kafka](docs/kafka.png) `kfk` – Kafka for kdb+

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kxsystems/kafka)](https://github.com/kxsystems/kafka/releases) [![Travis (.org) branch](https://img.shields.io/travis/kxsystems/kafka/master)](https://travis-ci.org/kxsystems/kafka/branches)



`kfk` is a thin wrapper for kdb+ around [`librdkafka`](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/).
It is part of the [_Fusion for kdb+_](https://code.kx.com/q/interfaces) interface collection.

This interface is supported for the following platforms

* 32- & 64-bit macOS and Linux
* 64-bit Windows

## New to kdb+ ?

Kdb+ is the world’s fastest time-series database, optimized for ingesting, analyzing and storing massive amounts of structured data. To get started with kdb+, see https://code.kx.com/q for downloads and developer information. For general information, visit https://kx.com/

## Documentation

-   [User guide](docs)
-   [Reference](docs/reference.md)


## Running

### Linux and macOS

#### Step 1

Build or install the latest version of `librdkafka`. The minimum required version is v0.11.0.

##### Install

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

##### Build from source 

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


#### Step 2

Compile, install and move shared object file to appropriate location.

1. Make sure you have `QHOME` set as an environment variable.

2. If your librdkafka install is not located in `$HOME/include` as defaulted by the above instructions set `KAFKA_ROOT` environment variable to the appropriate include location.

3. Run the following set of commands to set up the system as outlined

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

### Windows

At present the Windows build of the `.dll` for the kafka interface has been tested on Visual Studio 2017 with `librdkafka.redist.1.0.0`. The following are the steps completed to achieve this

1.  Install nuget for Windows: <https:/nuget.com/downloads>

2.  Install the redistributed version of librdkafka which is suitable for use with windows, documentation can be found [here](https://www.nuget.org/packages/librdkafka.redist/1.0.0).

    ```bash
    nuget install librdkafka.redist
    ```

3.  Ensure  you have Windows Visual Studio 2017 installed.

4.  Place the installed librdkafka.redist into an appropriate location (suggestions `%HOME%` or `%QHOME%`).
    For the remaining instructions, the path to the install is `C:/Users/jdoe/librdkafka.redist.1.0.0`

5.  Update `LIB` user environment variable to include the following path to `rdkafka.h` for appropriate Windows architecture in this case

    ```bash
    LIB = C:/Users/jdoe/librdkafka.redist.1.0.0/build/native/lib/win/x64/win-x64-Release/v120
    ```

6.  Update `PATH` system environment variable to include path to native folder for the appropriate computer architecture

    ```bash
    PATH = C:/Users/jdoe/librdkafka.redist.1.0.0/runtimes/win-x64/native
    ```

7.  Create a user environment variable `KAFKA_NATIVE` in line with the following example path

    ```bash
    KAFKA_NATIVE = C:/Users/jdoe/librdkafka.redist.1.0.0/build/native/include/
    ```

8.  Clone the Kafka interface from the KxSystems GitHub repo

    ```bash
    git clone https://github.com/kxsystems/kafka
    ```

9.  Move to the `kafka/build/` folder within the GitHub clone and run the following;

    ```bash
    call "build.bat"
    ```

10. If prompted for input, follow instructions accordingly.

11. Move the created `.dll` from the build folder to `%QHOME%/<arch>`

## Status

This interface is provided under an Apache 2.0 license.

If you find issues with the interface or have feature requests please [raise an issue](../..//issues).

To contribute to this project, please follow the [contribution guide](CONTRIBUTING.md).