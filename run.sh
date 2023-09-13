#!/usr/bin/env bash

#setsid ${TERMINAL} -e aarch64-linux-gnu-gdb \
#  -ex "target remote localhost:1234" \
#  -ex "source edk2/BaseTools/Scripts/efi_gdb.py" &

qemu-system-aarch64 \
  -machine type=virt,virtualization=on,pflash0=rom,pflash1=efivars \
  -cpu max \
  -smp 4 \
  -blockdev node-name=rom,driver=file,filename=QEMU_EFI.raw,read-only=true \
  -blockdev node-name=efivars,driver=file,filename=QEMU_VARS.raw \
  -drive file=disk.img,if=none,id=nvm \
  -device nvme,serial=deadbeef,drive=nvm \
  -drive file=fat:rw:VirtualDrive,format=raw,media=disk \
  -serial mon:stdio \
  -net none \
  -display none
#  \ -s \
#  -S
