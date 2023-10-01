#!/usr/bin/env bash

qemu-system-aarch64 \
  -machine type=virt,virtualization=on,gic-version=3 \
  -cpu max,pauth-impdef=on \
  -smp 1 \
  -m 4096 \
  -drive file=qemu_disk.img,if=none,format=raw,id=nvm \
  -device nvme,serial=deadbeef,drive=nvm \
  -drive file=fat:rw:VirtualDrive,format=raw,media=disk \
  -display none \
  -serial mon:stdio \
  -kernel linux/arch/arm64/boot/Image \
  -append "root=\"PARTLABEL=root\" rw"
#  -s \
#  -S
