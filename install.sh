#!/bin/bash

## @file install.sh
## @fileoverview Install shared object to `${QHOME}/[os-bitness]` and q scripts to `${QHOME}`.

if [ -z "$QHOME" ]
then
    echo "ERROR: QHOME environment not set. Installation failed."
    exit 1
fi

echo "Detected System"
echo "* OS: $OSTYPE"
echo "* TYPE: $HOSTTYPE"
echo "* MACHINE TYPE: $MACHTYPE"

# DETECT OS TYPE BEING USED
Q_PATH_SEP="/"
Q_HOST_TYPE=""
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        Q_HOST_TYPE="l"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        Q_HOST_TYPE="m"
elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        Q_HOST_TYPE="w"
        Q_PATH_SEP="\\"
elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        Q_HOST_TYPE="w"
        Q_PATH_SEP="\\"
elif [[ "$OSTYPE" == "win32" ]]; then
        Q_HOST_TYPE="w"
        Q_PATH_SEP="\\"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        Q_HOST_TYPE="l"
else
        echo "ERROR: OSTYPE $OSTYPE not currently supported by this script"
        echo "Please view README.md for installation instructions"
        exit 1
fi

# DETECT WHETHER 32 OR 64 BIT
Q_MACH_TYPE=""
if [[ "$HOSTTYPE" == "x86_64" ]]; then
    Q_MACH_TYPE="64"
else
    Q_MACH_TYPE="32"
fi

Q_SCRIPT_DIR=${QHOME}${Q_PATH_SEP}
Q_SHARED_LIB_DIR="${QHOME}${Q_PATH_SEP}${Q_HOST_TYPE}${Q_MACH_TYPE}${Q_PATH_SEP}"

# check destination directory exists
if [ ! -w "$Q_SCRIPT_DIR" ]; then
    echo "ERROR: Directory '$Q_SCRIPT_DIR' does not exist"
    exit 1
fi
if [ ! -w "$Q_SHARED_LIB_DIR" ]; then
    echo "ERROR: Directory '$Q_SHARED_LIB_DIR' does not exist"
    exit 1
fi
if [ ! -d q ]; then
    echo "ERROR: Directory 'q' does not exist. Please run from release package"
    exit 1
fi
if [ ! -d lib ]; then
    echo "ERROR: Directory 'lib' does not exist. Please run from release package"
    exit 1
fi

echo "Copying q script to $Q_SCRIPT_DIR ..."
cp q/* $Q_SCRIPT_DIR
if [ $? -ne 0 ]; then
    echo "ERROR: copy failed"
    exit 1
fi
echo "Copying shared lib to $Q_SHARED_LIB_DIR ..."
cp lib/* $Q_SHARED_LIB_DIR
if [ $? -ne 0 ]; then
    echo "ERROR: copy failed"
    exit 1
fi

echo "Install complete"
exit 0