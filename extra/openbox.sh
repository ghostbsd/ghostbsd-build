#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# lxde.sh,v 0.1 Thu Nov 1 15:08:37 ADT 2012 Eric
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

application="${BASEDIR}/usr/local/share/applications"

# Openbox default xinitrc.
cp -f extra/openbox/xinitrc ${BASEDIR}/usr/local/lib/X11/xinit/xinitrc

# Menu and rc for openbox. 
cp -f extra/openbox/menu.xml.${ARCH} ${BASEDIR}/usr/local/etc/xdg/openbox/menu.xml
cp -r extra/openbox/rc.xml ${BASEDIR}/usr/local/etc/xdg/openbox

# First remove all /usr/local/share/doc except cups
cd ${BASEDIR}/usr/local/share/doc
ls | grep -v cups | xargs rm -Rf 
cd -

# Remove all file not use.
cd ${BASEDIR}/usr
rm -rf games/* local/info/* share/info/* share/examples/*
rm -rf share/games/* share/doc/* share/dict/* local/share/examples/*
rm -rf local/share/texmf-dist/doc/* local/share/locale/*
cd -

# Ghostbsd theme.
cp -prf extra/ghostbsd/themes ${BASEDIR}/usr/local/share/
rm -rf ${BASEDIR}/usr/local/share/icons/Quid
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrast
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrast-SVG
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrastInverse
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrastLargePrint
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrastLargePrintInverse
rm -rf ${BASEDIR}/usr/local/share/icons/MateLargePrint
rm -rf ${BASEDIR}/usr/local/share/icons/LowContrastLargePrint
rm -rf ${BASEDIR}/usr/local/share/icons/Fog
rm -rf ${BASEDIR}/usr/local/share/icons/matefaenza
rm -rf ${BASEDIR}/usr/local/share/icons/matefaenzadark
rm -rf ${BASEDIR}/usr/local/share/icons/matefaenzagray
rm -f ${BASEDIR}/usr/local/share/icons/mate/icon-theme.cache
tar xfz extra/ghostbsd/icons.tar.gz -C ${BASEDIR}/usr/local/share

# Wallpapers
mkdir -p ${BASEDIR}/usr/local/share/backgrounds/openbox/
cp -prf extra/ghostbsd/wallpapers/* ${BASEDIR}/usr/local/share/backgrounds/openbox/

# Nitrogene user config.
mkdir -p ${BASEDIR}/root/.config
cp -prf extra/openbox/config/* ${BASEDIR}/root/.config
mkdir -p ${BASEDIR}/home/ghostbsd/.config
cp -prf extra/openbox/config/* ${BASEDIR}/home/ghostbsd/.config
#chgrp ghostbsd ${BASEDIR}/home/ghostbsd/.config
chmod g+rwx ${BASEDIR}/home/ghostbsd/.config

# Icon them 
echo 'gtk-icon-theme-name="brave-gray"' > ${BASEDIR}/home/ghostbsd/.gtkrc-2.0

if [ ! -d "${BASEDIR}/usr/local/share/gnome-background-properties" ] ; then
  mkdir -p ${BASEDIR}/usr/local/share/gnome-background-properties/
fi
cp -f extra/gnome/gnome-bsd.xml ${BASEDIR}/usr/local/share/gnome-background-properties/


# Cups adds.
cp -f extra/gnome/devfs.rules ${BASEDIR}/etc/
cat extra/gnome/make.conf >> ${BASEDIR}/etc/make.conf

#add sudo wheel permission
cp extra/gnome/sudoers ${BASEDIR}/usr/local/etc/ 

# To enable USB devices that are plugged in to be read/written
# by operators (i.e. the live user), this is needed:
if [ -z "$(cat ${BASEDIR}/etc/devd.conf| grep ugen[0-9])" ] ; then
    cat extra/gnome/devd.conf.extra >> ${BASEDIR}/etc/devd.conf
fi
if [ -z "$(cat ${BASEDIR}/etc/sysctl.conf| grep vfs.usermount)" ] ; then
    echo "vfs.usermount=1" >> ${BASEDIR}/etc/sysctl.conf
fi

# Set cursor theme instead of default from xorg
if [ -e ${BASEDIR}/usr/local/lib/X11/icons/default ] ; then
rm ${BASEDIR}/usr/local/lib/X11/icons/default 
fi
cd ${BASEDIR}/usr/local/lib/X11/icons
ln -sf $CURSOR_THEME default
cd - 

# Allow GDM auto login:
printf "
auth       required     pam_permit.so
account    required     pam_nologin.so
account    required     pam_unix.so
session    required     pam_permit.so
" > ${BASEDIR}/etc/pam.d/gdm-autologin

# Add bxpkg to the menue
cp -f extra/gnome/bxpkg-${ARCH}.desktop ${BASEDIR}/usr/local/share/applications/bxpkg.desktop
cp -f extra/gnome/m_icon.png ${BASEDIR}/usr/local/share/pixmaps/
cp -f extra/gnome/gnome-applications.menu ${BASEDIR}/usr/local/etc/xdg/menus
