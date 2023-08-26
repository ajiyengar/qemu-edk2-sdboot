#!/usr/bin/env bash

setsid ${TERMINAL} -e aarch64-linux-gnu-gdb -ex "target remote localhost:1234" &
qemu-system-aarch64 \
  -machine type=virt,virtualization=on,pflash0=rom,pflash1=efivars \
  -cpu max \
  -smp 4 \
  -blockdev node-name=rom,driver=file,filename=QEMU_EFI.raw,read-only=true \
  -blockdev node-name=efivars,driver=file,filename=QEMU_VARS.raw \
  -drive file=fat:rw:VirtualDrive,format=raw,media=disk \
  -serial mon:stdio \
  -net none \
  -display none \
  -s \
  -S
