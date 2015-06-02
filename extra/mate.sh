#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# mate.sh,v 1.0 Fri Sep  6 22:10:49 ADT 2013cd  Eric Turgeon
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

#cp -f extra/mate/xinitrc ${BASEDIR}/usr/local/etc/X11/xinit/xinitrc 

# Remove gmplayer.desktop
if [ -f "/usr/local/share/applications/gmplayer.desktop" ]; then
  rm ${BASEDIR}/usr/local/share/applications/gmplayer.desktop
fi


# to add 
cp -prf extra/mate/org.mate.panel.toplevel.gschema.xml ${BASEDIR}/usr/local/share/glib-2.0/schemas/
cp -prf extra/mate/org.mate.screensaver.gschema.xml ${BASEDIR}/usr/local/share/glib-2.0/schemas/

# GhostBSD shose station.
cp -rf extra/mate/chose-station ${BASEDIR}/usr/local/share/chose-station
install -C extra/mate/chose-station/main.py ${BASEDIR}/usr/local/bin/chose-station
cp extra/mate/chose-station/chose-station.desktop ${BASEDIR}/usr/local/etc/xdg/autostart/


# Compile schemas with glib
chroot ${BASEDIR} glib-compile-schemas /usr/local/share/glib-2.0/schemas/

# Set cursor theme instead of default from xorg
if [ -e ${BASEDIR}/usr/local/lib/X11/icons/default ] ; then
rm ${BASEDIR}/usr/local/lib/X11/icons/default 
fi
cd ${BASEDIR}/usr/local/lib/X11/icons
ln -sf $CURSOR_THEME default
cd -
