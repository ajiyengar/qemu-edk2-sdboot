#!/usr/bin/env bash

setsid ${TERMINAL} -e aarch64-linux-gnu-gdb \
  -ex "target remote localhost:1234" &

qemu-system-aarch64 \
  -machine type=virt,virtualization=on,gic-version=3,pflash0=rom,pflash1=efivars \
  -cpu max,pauth-impdef=on \
  -smp 1 \
  -m 4096 \
  -blockdev node-name=rom,driver=file,filename=QEMU_EFI.raw,read-only=true \
  -blockdev node-name=efivars,driver=file,filename=QEMU_VARS.raw \
  -drive file=qemu_disk.img,if=none,format=raw,id=nvm \
  -device nvme,serial=deadbeef,drive=nvm \
  -drive file=fat:rw:VirtualDrive,format=raw,media=disk \
  -serial mon:stdio \
  -net none \
  -display none \
  -s \
  -S

# -nographic
# -gdb tcp:localhost:1234 \
