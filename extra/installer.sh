#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# installer.sh, v1.3 Sunday, June 29 2014, Eric Turgeon
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

## put the installer in the system
cp -Rf extra/installer/gbi/ ${BASEDIR}/usr/local/etc/gbi
rm -r ${BASEDIR}/usr/share/pc-sysinstall/*
cp -Rf extra/installer/pc-sysinstall/ ${BASEDIR}/usr/share/pc-sysinstall/

## put the installer on the desktop
cp -pf extra/installer/GBI.desktop ${BASEDIR}${HOME}/Desktop/
chmod -R 1000:0 ${BASEDIR}${HOME}/Desktop/GBI.desktop


# copy gbi script to /usr/local/bin.
install -C extra/installer/gbi.sh ${BASEDIR}/usr/local/bin/gbi



