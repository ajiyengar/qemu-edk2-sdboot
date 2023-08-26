#!/usr/bin/env bash

set -e

###############
# Build UEFI
###############
make -C edk2/BaseTools

export ARCH=AARCH64
export COMPILER=GCC5
export GCC5_AARCH64_PREFIX=/usr/bin/aarch64-linux-gnu-
export GCC_MAJOR_VERSION=12
export WORKSPACE=$PWD
export PACKAGES_PATH=$WORKSPACE/edk2 #:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi
export BUILD_FLAGS="-D NETWORK_TLS_ENABLE=1 -D NETWORK_IP6_ENABLE=1 -D NETWORK_HTTP_BOOT_ENABLE=1 -D INCLUDE_TFTP_COMMAND=1"
#export BUILD_FLAGS="-D SECURE_BOOT_ENABLE=1 -D TPM2_ENABLE=1 -D NETWORK_TLS_ENABLE=1 -D NETWORK_IP6_ENABLE=1 -D NETWORK_HTTP_BOOT_ENABLE=1 -D INCLUDE_TFTP_COMMAND=1"

source edk2/edksetup.sh
build -a ${ARCH} -t ${COMPILER} -b DEBUG -p edk2/ArmVirtPkg/ArmVirtQemu.dsc --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"Ajay Custom Qemu" --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"Ajay Custom Qemu" ${BUILD_FLAGS}

dd of="QEMU_EFI.raw" if="/dev/zero" bs=1M count=64
dd of="QEMU_EFI.raw" if="Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd" conv=notrunc
dd of="QEMU_VARS.raw" if="/dev/zero" bs=1M count=64
dd of="QEMU_VARS.raw" if="Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_VARS.fd" conv=notrunc
