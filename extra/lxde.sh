#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# lxde.sh,v 1.2_1 Monday, January 31 2011 00:49:48 Eric
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

application="${BASEDIR}/usr/local/share/applications"

cp -f extra/lxde/xinitrc ${BASEDIR}/usr/local/lib/X11/xinit/xinitrc
cp -f extra/installer/gbi/logo.png ${BASEDIR}/usr/local/share/lxde/images/logo.png
cp -f extra/lxde/panel ${BASEDIR}/usr/local/share/lxpanel/profile/LXDE/panels/
cp -f extra/lxde/panel ${BASEDIR}/usr/local/share/lxpanel/profile/default/panels/
cp -f extra/lxde/desktop.conf ${BASEDIR}/usr/local/etc/xdg/lxsession/LXDE/
cp -rf extra/lxde/lxde-rc.xml ${BASEDIR}/usr/local/share/lxde/openbox/rc.xml

# Lxterminal configuration file 
cp -f extra/lxde/lxterminal.conf ${BASEDIR}/usr/local/share/lxterminal/

# Mixmos .desktop
cp -f extra/lxde/mixmos.desktop ${BASEDIR}/usr/local/share/applications/

# Removing Gnome in GDM.
cd ${BASEDIR}/usr/local/share/xsessions
rm -rf gnome.desktop openbox-gnome.desktop openbox-kde.desktop
cd -

# First remove all /usr/local/share/doc except cups
#cd ${BASEDIR}/usr/local/share/doc
#ls | grep -v cups | xargs rm -Rf 
#cd -
#cd ${BASEDIR}/usr
#rm -rf games/* local/info/* share/info/* share/examples/*
#rm -rf share/games/fortune/* share/doc/* share/dict/* local/share/examples/*
#rm -rf local/share/texmf-dist/doc/* local/share/locale/*
#cd -

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
cp -prf extra/ghostbsd/wallpapers/* ${BASEDIR}/usr/local/share/lxde/wallpapers/
cp -f extra/lxde/pcmanfm.conf ${BASEDIR}/usr/local/etc/xdg/pcmanfm/LXDE/pcmanfm.conf


if [ -f ${BASEDIR}/usr/local/share/applications/gksu.desktop ] ; then
        /usr/bin/sed -i "" "s@/usr/bin/x-terminal-emulator@/usr/local/bin/lxterminal@" ${BASEDIR}/usr/local/share/applications/gksu.desktop
fi

if [ -f ${BASEDIR}/usr/local/share/applications/cups.desktop ] ; then
        /usr/bin/sed -i "" "s@htmlview@firefox@" ${BASEDIR}/usr/local/share/applications/cups.desktop
fi

if [ -f ${BASEDIR}/usr/local/share/applications/evince.desktop ] ; then
        /usr/bin/sed -i "" "s@NoDisplay=true@NoDisplay=false@" ${BASEDIR}/usr/local/share/applications/evince.desktop
fi

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

