#!/bin/sh

#Deps sd-boot: pacman -S meson ninja pyelftools gperf
#Deps esp: parted mtools

set -e

#meson setup --default-library static --prefer-static --cross-file meson_aarch64.txt systemd/build_aarch64/ systemd/
#ninja -C systemd/build_aarch64/ systemd-boot

dd if=/dev/zero of=esp.img bs=512 count=93750
parted esp.img -s -a minimal mklabel gpt
parted esp.img -s -a minimal mkpart EFI FAT16 2048s 93716s
parted esp.img -s -a minimal toggle 1 boot

dd if=/dev/zero of=/tmp/part.img bs=512 count=91669
mformat -i /tmp/part.img -h 32 -t 32 -n 64 -c 1

mmd -i /tmp/part.img ::/EFI
mmd -i /tmp/part.img ::/EFI/BOOT
mcopy -i /tmp/part.img systemd/build_aarch64/src/boot/efi/systemd-bootaa64.efi ::/EFI/BOOT/BOOTAA64.efi

dd if=/tmp/part.img of=esp.img bs=512 count=91669 seek=2048 conv=notrunc

mkdir -p VirtualDrive
#cp systemd/build_aarch64/src/boot/efi/systemd-bootaa64.efi VirtualDrive/
echo 'world' > VirtualDrive/hello.txt
