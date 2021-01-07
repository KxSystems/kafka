#!/bin/bash

## @file travis_setup_win.sh
## @overview Install rdkafka

cd cbuild
mkdir librdkafka

if [[ $TRAVIS_OS_NAME == windows ]]; then
    curl -o ./nuget.exe -L https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
    chmod a+x ./nuget.exe
    ./nuget.exe install librdkafka.redist -Version 1.5.3
    mkdir librdkafka/install
    mkdir librdkafka/install/lib
    mkdir librdkafka/install/include
    mkdir librdkafka/install/bin
    cp -r librdkafka.redist.1.5.3/build/native/lib/win/x64/win-x64-Release/v120/ librdkafka/install/lib/
    cp -r librdkafka.redist.1.5.3/build/native/include librdkafka/install/include/
    cp -r librdkafka.redist.1.5.3/runtimes/win-x64/native librdkafka/install/bin/
else
    # Linux and MacOSX
    wget https://github.com/edenhill/librdkafka/archive/v1.6.0-ARM64-PRE10.tar.gz
    tar xzf v1.6.0-ARM64-PRE10.tar.gz -C librdkafka --strip-components=1
    cd librdkafka
    mkdir install
    ./configure --prefix=install/ --disable-sasl --disable-lz4 --disable-ssl --mbits=64
    make 
    make install
    cd ..
fi

# cbuild/../
cd ..