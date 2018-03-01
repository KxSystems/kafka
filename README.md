# `kfk` – Kafka for kdb+


`kfk` is a thin wrapper for kdb+ around [librdkadka](https://github.com/edenhill/librdkafka) C API for [Kafka](https://kafka.apache.org/). 
It is part of the [_Fusion for kdb+_](http://code.kx.com/q/interfaces/fusion/) interface collection.

Please [report issues](https://github.com/KxSystems/kafka/issues) in this repository.

See [code.kx.com/q/interfaces/kafka](http://code.kx.com/q/interfaces/kafka/) for full documentation.


## Build and install

### Step 1

Build and install the latest version of `librdkafka`. The minimum required version is v0.11.0.

#### Requirements

As noted on the [librdkafka page](https://github.com/edenhill/librdkafka#requirements)
```
The GNU toolchain
GNU make
pthreads
zlib (optional, for gzip compression support)
libssl-dev (optional, for SSL and SASL SCRAM support)
libsasl2-dev (optional, for SASL GSSAPI support)
```
To build 32-bit versions on 64-bit OS you need to have 32-bit versions of libraries and a toolchain.
```
#CentOS/RHEL
sudo yum install glibc-devel.i686 libgcc.i686 libstdc++.i686 zlib-devel.i686
# Ubuntu
sudo apt-get install gcc-multilib
```

#### Librdkafka

##### Package installation
```
#macOS
brew install librdkafka
#Ubuntu/Debian(unstable)
sudo apt-get install librdkafka-dev
#RHEL/CentOS
sudo yum install librdkafka-devel
```

##### Building from source 

#### macOS and Linux
```bash
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
make clean  # to make sure nothing left from previous build or if upgrading/rebuilding
# If using OpenSSL, remove --disable-ssl from configure command below
# On macOS with OpenSSL you might need to set `export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl/1.0.2k` before proceeding


// 32 bit
./configure --prefix=$HOME --disable-sasl --disable-lz4 --disable-ssl --mbits=32 
// 64 bits
./configure --prefix=$HOME --disable-sasl --disable-lz4 --disable-ssl --mbits=64

make
make install
```

#### Windows (to be added)
Using the Nuget redistributable (https://www.nuget.org/packages/librdkafka.redist)
```
nuget install librdkafka.redist
```


### Step 2

Compile and install a shared object (it will be installed to $QHOME/<arch>). Make sure you have QHOME environment set.
```bash
// in kfk source folder
make
make install
```
Note: If compiling dynamically linked `libkfk.so` make sure you have `librdkafka.so.1` in your `LD_LIBRARY_PATH`.
```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/lib
```


## Documentation

See [code.kx.com/q/interfaces/kafka](http://code.kx.com/q/interfaces/kafka/).


