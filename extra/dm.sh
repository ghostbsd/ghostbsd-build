#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# dm.sh,v 0.1
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

# Allow GDM auto login:
printf "
auth       required     pam_permit.so
account    required     pam_nologin.so
account    required     pam_unix.so
session    required     pam_permit.so
" > ${BASEDIR}/etc/pam.d/gdm-autologin

# Use a GDM config file which enables auto login as the live user:
cp -f extra/dm/custom.conf ${BASEDIR}/usr/local/etc/gdm/custom.conf

cp -f extra/ghostbsd/wallpapers/ghost_horizon.png ${BASEDIR}/usr/local/share/pixmaps/backgrounds/gnome/background-default.jpg

#slim experimentation.
#cp -f extra/dm/slim.conf ${BASEDIR}/usr/local/etc/slim.conf
#sed -i "" "/ttyv8/s/xdm/slim/g" ${BASEDIR}/etc/ttys
#sed -i "" "/ttyv8/s/off/on/g" ${BASEDIR}/etc/ttys

#Gconf GhostBSD defaults.
mkdir -p /usr/local/etc/default
rm -rf ${BASEDIR}/usr/local/etc/gconf/gconf.xml.defaults
cp -f extra/dm/gnome-desktop-settings /usr/local/etc/default/
cp -f extra/dm/get_settings /usr/local/etc/default/
mkdir -p ${BASEDIR}/usr/local/etc/default
sh /usr/local/etc/default/get_settings
rm -rf /usr/local/etc/default
cp -prf /usr/local/etc/gconf/* ${BASEDIR}/usr/local/etc/gconf
