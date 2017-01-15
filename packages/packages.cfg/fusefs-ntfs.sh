#!/bin/sh

if [ -e /usr/local/bin/ntfs-3g ]; then
    ln -s /usr/local/bin/ntfs-3g /sbin/mount_ntfs
fi
