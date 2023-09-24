#!/usr/bin/env bash

set -e

export CROSS_COMPILE=$PWD/tools/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

###############
# Build Linux
###############
make -C linux ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE virtconfig
make -C linux -j$(nproc) ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE Image modules dtbs


###############
# Build Toybox
###############
make -C toybox ARCH=aarch64 CROSS_COMPILE=${CROSS_COMPILE} defconfig toybox


###############
# Build Shell
###############
(cd mksh; CC=${CROSS_COMPILE}cc TARGET_OS=Linux sh Build.sh -r)

