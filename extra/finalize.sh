#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# finalize.sh,v 1.0 Wed 17 Jun 19:42:49 ADT 2015cd  Ovidiu Angelescu
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

# Remove gmplayer.desktop
if [ -f "/usr/local/share/applications/gmplayer.desktop" ]; then
  rm ${BASEDIR}/usr/local/share/applications/gmplayer.desktop
fi

# Set cursor theme instead of default from xorg
if [ -e ${BASEDIR}/usr/local/lib/X11/icons/default ] ; then
rm ${BASEDIR}/usr/local/lib/X11/icons/default 
fi
cd ${BASEDIR}/usr/local/lib/X11/icons
ln -sf $CURSOR_THEME default
cd -
# Setting installer
rm -rf ${BASEDIR}/usr/sbin/pc-sysinstall
rm -rf ${BASEDIR}/usr/share/pc-sysinstall

# enable pcdm if installed
if [ -e $(which pcdm) ] ; then 
    sed -i '' 's@#pcdm_enable="YES"@pcdm_enable="YES"@g' ${BASEDIR}/etc/rc.conf
fi

# .gtk_bookmarks
printf "file:///home/${GHOSTBSD_USER}/Documents Documents
file:///home/${GHOSTBSD_USER}/Downloads Downloads
file:///home/${GHOSTBSD_USER}/Movies Movies
file:///home/${GHOSTBSD_USER}/Music Music
file:///home/${GHOSTBSD_USER}/Pictures Pictures
" > ${BASEDIR}/home/${GHOSTBSD_USER}/.gtk-bookmarks

chroot ${BASEDIR}    chmod g+rwx /home/${GHOSTBSD_USER}/.gtk-bookmarks
chroot ${BASEDIR}    mkdir -p /home/${GHOSTBSD_USER}/Documents
chroot ${BASEDIR}    chmod g+rwx /home/${GHOSTBSD_USER}/Documents
chroot ${BASEDIR}    mkdir -p /home/${GHOSTBSD_USER}/Downloads
chroot ${BASEDIR}    chmod g+rwx /home/${GHOSTBSD_USER}/Downloads
chroot ${BASEDIR}    mkdir -p /home/${GHOSTBSD_USER}/Movies 
chroot ${BASEDIR}    chmod g+rwx /home/${GHOSTBSD_USER}/Movies
chroot ${BASEDIR}    mkdir -p /home/${GHOSTBSD_USER}/Music
chroot ${BASEDIR}    chmod g+rwx /home/${GHOSTBSD_USER}/Music
chroot ${BASEDIR}    mkdir -p /home/${GHOSTBSD_USER}/Pictures
chroot ${BASEDIR}    chmod g+rwx /home/${GHOSTBSD_USER}/Pictures

set -e

chown -R 1000:0 ${BASEDIR}/home/${GHOSTBSD_USER}

mkdir -p ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop
chown -R 1000:0 ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop


if [ -e ${BASEDIR}/usr/local/share/applications/ghostbsd-irc.desktop ] ; then
    cp -af ${BASEDIR}/usr/local/share/applications/ghostbsd-irc.desktop \
    ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop
    chown -R 1000:0 ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop/ghostbsd-irc.desktop
    chmod +x ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop/ghostbsd-irc.desktop
fi    

if [ -e ${BASEDIR}/usr/local/share/applications/gbi.desktop ] ; then
    cp -af ${BASEDIR}/usr/local/share/applications/gbi.desktop \
    ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop
    chown -R 1000:0 ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop/gbi.desktop
    chmod +x ${BASEDIR}/home/${GHOSTBSD_USER}/Desktop/gbi.desktop
fi
