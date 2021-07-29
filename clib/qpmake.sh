#!/bin/sh

# @file qpmake.sh
# @overview
# Add dependencies and install kafkakdb.
# @note
# Make sure you downloaded and placed transformer.qpk under `clib/`.

## Add librdkafka ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

set -e
apk add --update alpine-sdk
apk add curl cmake openssl-dev librdkafka-dev

# Copy kafka related library and header files into /usr/local/lib/librdkafka,
# which is used as a default value of `KAFKA_INSTALL_DIR` inside CMakeLists.txt.
mkdir -p /usr/local/lib/librdkafka/include/librdkafka/
mkdir -p /usr/local/lib/librdkafka/lib
cp /usr/lib/librdkafka* /usr/local/lib/librdkafka/lib/
cp /usr/include/librdkafka/rdkafka.h /usr/local/lib/librdkafka/include/librdkafka/

## Install transformer ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

## The transformer package should be downloaded in advance.
## qp pull gitlab.com/kxdev/interop/transformer/transformer.qpk 0.1.0
unzip transformer.qpk
cp transformer/src/* /usr/local/lib/

## Install kafkakdb ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

#find /tmp -exec ls -l  {} \;

mkdir build
cd build
## Build with USE_TRANSFORMER flag
## TODO: Is there any way to parameterize this?
cmake ../ -DUSE_TRANSFORMER:BOOL=ON
cmake --build . --target install
cd ../

## Copy kafkakdb.so so that qpacker can find the artefact.
cp build/kafkakdb/lib/kafkakdb.so qpbuild/kafkakdb.so
