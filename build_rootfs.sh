#!/usr/bin/env bash

set -e

export CROSS_COMPILE=$PWD/tools/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

[[ -d /tmp/rootfs ]] && { sudo rm -rf /tmp/rootfs; }

###############
# Make Rootfs
###############
mkdir -p /tmp/rootfs/{dev,etc,home,mnt,root,proc,sys/firmware/efi/efivars,tmp,usr/{bin,lib/modules},var/log}
ln -s usr/bin /tmp/rootfs/bin
ln -s usr/bin /tmp/rootfs/sbin
ln -s usr/lib /tmp/rootfs/lib
ln -s usr/lib /tmp/rootfs/lib64
ln -s bin /tmp/rootfs/usr/sbin
ln -s lib /tmp/rootfs/usr/lib64
chmod a+rwxt /tmp/rootfs/tmp

# Based on https://github.com/landley/toybox/blob/master/scripts/mkroot.sh
cat > /tmp/rootfs/sbin/init << 'EOF' &&
#!/bin/sh

export HOME=/home PATH=/bin:/sbin

#mount -t devtmpfs dev /dev
exec 0<>/dev/console 1>&0 2>&1
for i in /,fd /0,stdin /1,stdout /2,stderr
do ln -sf /proc/self/fd${i/,*/} /dev/${i/*,/}; done
mkdir -p /dev/shm
chmod +t /dev/shm
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
mount -t tmpfs tmpfs /tmp
ifconfig lo 127.0.0.1

echo 3 > /proc/sys/kernel/printk     #cat /dev/kmsg

echo -e '\e[?7hType exit when done.' #Vertical autowrap
exec oneit /bin/sh
EOF
chmod +x /tmp/rootfs/sbin/init &&

# Google's nameserver, passwd+group with special (root/nobody) accounts + guest
echo "nameserver 8.8.8.8" > /tmp/rootfs/etc/resolv.conf &&
cat > /tmp/rootfs/etc/passwd << 'EOF' &&
root:x:0:0:root:/root:/bin/sh
guest:x:500:500:guest:/home/guest:/bin/sh
nobody:x:65534:65534:nobody:/proc/self:/dev/null
EOF
echo -e 'root:x:0:\nguest:x:500:\nnobody:x:65534:' > /tmp/rootfs/etc/group


####################
# Copy Linux Modules
####################
make -C linux -j$(nproc) ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=/tmp/rootfs modules_install

#################
# Copy Toybox and
# Dependencies
#################
make -C toybox ARCH=aarch64 CROSS_COMPILE=${CROSS_COMPILE} PREFIX=/tmp/rootfs/bin install_flat

echo "toybox Dependencies:"
${CROSS_COMPILE}readelf -a toybox/toybox | grep -E "(program interpreter)|(Shared library)"

export SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -L ${SYSROOT}/lib64/{ld-2.33.so,libcrypt.so.1,libm.so.6,libresolv.so.2,libc.so.6} /tmp/rootfs/usr/lib/
ln -s ld-2.33.so /tmp/rootfs/lib/ld-linux-aarch64.so.1
ln -s ../lib/ld-2.33.so /tmp/rootfs/usr/bin/ld.so

###############
# Copy Shell
###############
cp mksh/mksh /tmp/rootfs/bin
ln -s mksh /tmp/rootfs/bin/sh
cp mksh/dot.mkshrc /tmp/rootfs/etc/mkshrc

echo "mksh Dependencies:"
${CROSS_COMPILE}readelf -a mksh/mksh | grep -E "(program interpreter)|(Shared library)"

#################
# Add devices and
# change ownership
#################
sudo chown -R root:root /tmp/rootfs

##################
# Create InitRamFs
##################
#sudo /bin/sh -c "( cd /tmp/rootfs && find . -printf '%P\n' | cpio -o -H newc -R +0:+0 | gzip ) > initramfs.cpio.gz"
