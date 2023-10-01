#!/usr/bin/env bash

set -e

export CROSS_COMPILE=$PWD/tools/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

###############
# Build Linux
###############
make -C linux ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE LOCALVERSION="-ajay" virtconfig
#Enable EFIStub debugging
sed -i 's/# CONFIG_DEBUG_EFI is not set/CONFIG_DEBUG_EFI=y/g' linux/.config
#Enable GDB scripts
sed -i 's/# CONFIG_GDB_SCRIPTS is not set/CONFIG_GDB_SCRIPTS=y/g' linux/.config
#GDB debug scripts prefer reduced debug to not be enabled
sed -i 's/CONFIG_DEBUG_INFO_REDUCED=y/# CONFIG_DEBUG_INFO_REDUCED is not set\n# CONFIG_DEBUG_INFO_BTF is not set/g' linux/.config
#Disable KASLR
sed -i 's/CONFIG_RANDOMIZE_BASE=y/# CONFIG_RANDOMIZE_BASE is not set/g' linux/.config
#Enable NVMe
sed -i 's/CONFIG_NVME_CORE=m/CONFIG_NVME_CORE=y/g' linux/.config
sed -i 's/CONFIG_BLK_DEV_NVME=m/CONFIG_BLK_DEV_NVME=y/g' linux/.config

make -C linux -j$(nproc) ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE LOCALVERSION="-ajay" Image modules scripts_gdb

###############
# Build Toybox
###############
make -C toybox ARCH=aarch64 CROSS_COMPILE=${CROSS_COMPILE} defconfig toybox

###############
# Build Shell
###############
(cd mksh; CC=${CROSS_COMPILE}cc TARGET_OS=Linux sh Build.sh -r)

