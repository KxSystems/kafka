#!/bin/bash

# @file qpmake.sh
# @overview
# Add dependencies and install kafkakdb.
# @note
# Make sure you downloaded and placed transformer.qpk under `clib/`.

## Add librdkafka ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

set -e
apk add --update alpine-sdk && apk add cmake && apk add openssl-dev && apk add librdkafka-dev

# Copy kafka related library and header files into /usr/local/lib/librdkafka,
# which is used as a default value of `KAFKA_INSTALL_DIR` inside CMakeLists.txt.
mkdir -p /usr/local/lib/librdkafka/include/librdkafka/
mkdir -p /usr/local/lib/librdkafka/lib
cp /usr/lib/librdkafka* /usr/local/lib/librdkafka/lib/
cp /usr/include/librdkafka/rdkafka.h /usr/local/lib/librdkafka/include/librdkafka/

## Install kafkakdb ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

mkdir clib/build
cd clib/build
## Build with USE_TRANSFORMER flag
cmake ../ -DUSE_TRANSFORMER:BOOL=ON
cmake --build . --target install
## Copy kafkakdb.so so that qpacker can find the artefact.
cp build/kafkakdb/libs/kafkakdb.so qpbuild/kafkakdb.so
cd ../..
