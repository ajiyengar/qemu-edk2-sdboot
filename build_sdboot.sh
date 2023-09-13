#!/bin/sh

#Deps sd-boot: pacman -S meson ninja pyelftools gperf
#Deps disk: parted mtools

set -e

#Cross compile systemd-boot for aarch64
meson setup --default-library static --prefer-static --cross-file meson_aarch64.txt systemd/build_aarch64/ systemd/
ninja -C systemd/build_aarch64/ systemd-boot

#Create GPT formatted disk with empty EFI system partition
dd if=/dev/zero of=disk.img bs=512 count=93750
parted disk.img -s -a minimal mklabel gpt
parted disk.img -s -a minimal mkpart EFI FAT16 2048s 93716s
parted disk.img -s -a minimal toggle 1 boot

#Create empty FAT volume for EFI system partition
dd if=/dev/zero of=/tmp/esp.img bs=512 count=91669
mformat -i /tmp/esp.img -h 32 -t 32 -n 64 -c 1
mlabel -i /tmp/esp.img ::"NVME ESP"

#Inject systemd-boot.efi as BOOTAA64.efi into ESP FAT volume
mmd -i /tmp/esp.img ::/EFI
mmd -i /tmp/esp.img ::/EFI/BOOT
mcopy -i /tmp/esp.img systemd/build_aarch64/src/boot/efi/systemd-bootaa64.efi ::/EFI/BOOT/BOOTAA64.efi

#Inject ESP into disk
dd if=/tmp/esp.img of=disk.img bs=512 count=91669 seek=2048 conv=notrunc

#Virtual drive for simple host/qemu file sharing
mkdir -p VirtualDrive
#cp systemd/build_aarch64/src/boot/efi/systemd-bootaa64.efi VirtualDrive/
echo 'world' > VirtualDrive/hello.txt
