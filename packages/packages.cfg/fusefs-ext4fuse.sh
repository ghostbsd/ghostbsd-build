#!/bin/sh

# load fuse kernel module for all fuse* progs
grep -q "fuse_load" /boot/loader.conf
if [ $? -ne 0 ]; then
    echo 'fuse_load="YES"' >> /boot/loader.conf
fi

grep -q "fuse" /boot/grub/grub.cfg
if [ $? -ne 0 ]; then
    sed -i '' '/set kFreeBSD.kern.vty=vt/a\
\  kfreebsd_module_elf /boot/kernel/fuse.ko\
' /boot/grub/grub.cfg
fi

if [ -e /usr/local/bin/ext4fuse ]; then
    ln -s /usr/local/bin/ext4fuse /sbin/mount_ext4fs
fi