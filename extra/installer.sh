#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# installer.sh,v 1.2_1 Monday, January 31 2011 00:53:46 Eric
#
set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

# Installer backend.
if [ ! -d ${BASEDIR}/usr/local/etc/gbi ]; then
    mkdir -p ${BASEDIR}/usr/local/etc/gbi
fi

###
## put the installer in the system
####
cp -Rf extra/installer/gbi/ ${BASEDIR}/usr/local/etc/gbi
rm -r ${BASEDIR}/usr/share/pc-sysinstall/*
cp -Rf extra/installer/pc-sysinstall/ ${BASEDIR}/usr/share/pc-sysinstall/

###
## put a installer on the desktop
####
if [ ! -f /usr/local/share/applications/GBI.desktop ]; then
  cp -pf extra/installer/GBI.desktop ${BASEDIR}${HOME}/Desktop/
  chmod g+rwx ${BASEDIR}${HOME}/Desktop/GBI.desktop
fi

# copy gbi and ginstall script to /usr/bin.
cp -Rf extra/installer/bin/ ${BASEDIR}/usr/bin



