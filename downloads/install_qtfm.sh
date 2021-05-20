#!/bin/bash

## @file install_qtfm.sh
## @overview Install transformer library.

## Debug or Release
BUILD_TYPE=$1

## Clone the repository of transformer library
if [[ -d transformer ]]; then
  rm -fr transformer
fi
git clone https://github.com/mshimizu-kx/transformer.git
cd transformer

## Build a library
./install.sh ${BUILD_TYPE} shared

## Copy artefact and other dependencies.
cp clib/build/clib/q_message_transformer/q/transformer.q ../../q/
cp clib/include/qtfm.h ../../clib/include/

cd ../
