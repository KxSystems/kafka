#!/bin/bash
set -e
set -x

make KAFKA_ROOT=$BUILD_PREFIX && make install
mkdir -p $PREFIX/lib/q/mod/kx
cp -r $PREFIX/kafka $PREFIX/lib/q/mod/kx/
ls $PREFIX/lib/q/mod/kx/kafka