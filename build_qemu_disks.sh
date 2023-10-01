#!/usr/bin/env bash

#Dependencies (Arch): parted mtools udisks2 jq

set -e

DISK_SZ=$((1124*1024*1024))
ESP_SZ=$((100*1024*1024))
ALIGN=2048

#Create GPT formatted disk with empty EFI system partition
ESP_END_S=$((ESP_SZ/512+$ALIGN))
dd if=/dev/zero of=/tmp/qemu_disk.img bs=512 count=$(($DISK_SZ/512))
parted /tmp/qemu_disk.img -s -a optimal mklabel gpt
parted /tmp/qemu_disk.img -s -a optimal mkpart EFI ${ALIGN}s $((ESP_END_S-1))s
parted /tmp/qemu_disk.img -s set 1 boot on

#Create Linux Root partition alinged to ALIGN
REM_SZ_S=$(parted /tmp/qemu_disk.img -j -s unit s print free | \
  jq '.disk.partitions.[] | select(.type|test("free")) | .end' | \
  sed -E 's/[^0-9]*//g' | sort -r -n | head -n 1)
REM_SZ_S=$(( $REM_SZ_S / $ALIGN * $ALIGN - 1 ))
parted /tmp/qemu_disk.img -s -a optimal mkpart root ${ESP_END_S}s ${REM_SZ_S}s

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

#Inject kernel into ESP FAT volume
mcopy -i /tmp/esp.img linux/arch/arm64/boot/Image ::/
mmd -i /tmp/esp.img ::/loader
mmd -i /tmp/esp.img ::/loader/entries

#Inject systemd-boot configs into ESP FAT volume
cat > /tmp/loader.conf << 'EOF' &&
timeout 3
editor 1
auto-firmware 1
EOF
mcopy -i /tmp/esp.img /tmp/loader.conf ::/loader/loader.conf

PARTUUID=$(parted /tmp/qemu_disk.img -j -s unit s print | \
  jq '.disk.partitions.[] | select(.name|test("root")) | .uuid' | \
  tr -d '"')
cat > /tmp/linux.conf <<EOF &&
title   Linux
linux   /Image
options root=PARTUUID=$PARTUUID rw
EOF
#options root="PARTLABEL=root" rw
mcopy -i /tmp/esp.img /tmp/linux.conf ::/loader/entries/linux.conf

#Inject ESP into disk
dd if=/tmp/esp.img of=/tmp/qemu_disk.img bs=512 count=$(($ESP_SZ/512)) seek=$ALIGN conv=notrunc
#rm /tmp/esp.img

#Inject RootFS into disk
ROOTFS_SZ_S=$(( $REM_SZ_S - $ESP_END_S + 1 ))
dd if=/dev/zero of=/tmp/rootfs.img bs=512 count=$ROOTFS_SZ_S
mkfs.ext4 -d /tmp/rootfs /tmp/rootfs.img
dd if=/tmp/rootfs.img of=/tmp/qemu_disk.img bs=512 count=$ROOTFS_SZ_S seek=$ESP_END_S conv=notrunc
#rm /tmp/rootfs.img

#Copy into project directory
cp /tmp/qemu_disk.img .
#rm /tmp/qemu_disk.img

#Virtual drive for simple host/qemu file sharing
mkdir -p VirtualDrive
echo 'world' > VirtualDrive/hello.txt
