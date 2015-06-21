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

