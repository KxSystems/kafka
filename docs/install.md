# Kafka kdb+ library installation

Note: From version 2.0.0 Kdb-x is required. If you have older version of Kdb, use 1.x.x release/branch.

## Build/Install

### Linux and macOS

#### Step 1

Build or install the latest version of `librdkafka`. The minimum required version is v0.11.0.

##### Install dependencies

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

##### Installing a Release

It is recommended that a user install this module through a release. 

[Download a release](https://github.com/KxSystems/arrowkdb/releases) and then unzip to your module directory. The following example assumes the default install location for KDB-X.

```
unzip arrowkdb-l64.zip -d ~/.kx/mod
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

1. If your librdkafka install is not located in `$HOME/include` as defaulted by the above instructions set `KAFKA_ROOT` environment variable to the appropriate include location.

2. Run the following set of commands to set up the system as outlined

```bash
// in kfk source folder
make install
// move installed `.so` to some directory that's on your `$QPATH`, details: https://docs.kx.com/latest/kdb-x/integrations/module-management-qsg.htm#Search_path
mv ./out/kafka <your module library>
```

Note: If compiling dynamically linked `libkfk.so` make sure you have `librdkafka.so.1` in your `LD_LIBRARY_PATH`.

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/lib
```
