#!/bin/sh

if [ -e /usr/local/bin/ext4fuse ]; then
    ln -s /usr/local/bin/ext4fuse /sbin/mount_ext4fs
fi