#!/usr/bin/env bash

#Dependencies (Arch): parted mtools udisks2 jq

set -e
DISK_SZ=$((120*1024*1024))
ESP_SZ=$((46*1024*1024))
ALIGN=2048

#Create GPT formatted disk with empty EFI system partition
dd if=/dev/zero of=/tmp/qemu_disk.img bs=512 count=$(($DISK_SZ/512))
parted /tmp/qemu_disk.img -s -a optimal mklabel gpt
parted /tmp/qemu_disk.img -s -a optimal mkpart EFI ${ALIGN}s $((($ESP_SZ)/512+2048-1))s
parted /tmp/qemu_disk.img -s set 1 boot on

#Create Linux Root partition alinged to ALIGN
REM_SZ=$(parted /tmp/qemu_disk.img -j -s unit s print free | jq '.disk.partitions.[] | select(.type|test("free")) | .end' | sed -E 's/[^0-9]*//g' | sort -r -n | head -n 1)
REM_SZ=$(( $REM_SZ / $ALIGN * $ALIGN - 1))
parted /tmp/qemu_disk.img -s -a optimal mkpart root $((($ESP_SZ)/512+2048))s ${REM_SZ}s

#Create empty FAT volume for EFI system partition
dd if=/dev/zero of=/tmp/esp.img bs=512 count=$(($ESP_SZ/512))
mformat -i /tmp/esp.img -c 1 -h 32 -s 32 -v "NVME ESP" \
  -t $(($ESP_SZ/(1*32*32*512)-1))

#Inject systemd-boot.efi as BOOTAA64.efi into ESP FAT volume
mmd -i /tmp/esp.img ::/EFI
mmd -i /tmp/esp.img ::/EFI/BOOT
mcopy -i /tmp/esp.img \
  systemd/build_aarch64/src/boot/efi/systemd-bootaa64.efi \
  ::/EFI/BOOT/BOOTAA64.efi

#Inject ESP into disk
dd if=/tmp/esp.img of=/tmp/qemu_disk.img bs=512 count=$(($ESP_SZ/512)) seek=$ALIGN conv=notrunc

#Virtual drive for simple host/qemu file sharing
mkdir -p VirtualDrive
echo 'world' > VirtualDrive/hello.txt
