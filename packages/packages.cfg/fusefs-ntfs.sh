#!/bin/sh

# load fuse kernel module for all fuse* progs
echo 'fuse_load="YES"' >> /boot/loader.conf

# Adding fuse kernel module to /boot/grub/grub.cfg
