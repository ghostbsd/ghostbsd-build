#!/bin/sh
#
# Copyright (c) 2015 GhostBSD
#
# See COPYING for license terms.
#
# dm.sh,v 0.1

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

# cp -rf extra/dm/default/* ${BASEDIR}/usr/local/share/PCDM/themes/default
# cp -rf ${BASEDIR}/usr/local/share/backgrounds/ghostbsd/GreenLeaf.jpg ${BASEDIR}/usr/local/share/PCDM/themes/default/background.jpg
# sed -i "" 's/${command} stop/# ${command} stop/g' ${BASEDIR}/usr/local/etc/rc.d/pcdm

# # Auto login for user ghostbsd.
# sed -i "" "s/ENABLE_AUTO_LOGIN=FALSE/ENABLE_AUTO_LOGIN=TRUE/g" ${BASEDIR}/usr/local/etc/pcdm.conf.dist
# sed -i "" "s/AUTO_LOGIN_USER=no-username/AUTO_LOGIN_USER=ghostbsd/g" ${BASEDIR}/usr/local/etc/pcdm.conf.dist
# sed -i "" "s/AUTO_LOGIN_PASSWORD=no-password/AUTO_LOGIN_PASSWORD=ghostbsd/g" ${BASEDIR}/usr/local/etc/pcdm.conf.dist

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
printf "# GDM configuration storage

[daemon]
# Uncoment the line below to force the login screen to use Xorg
#WaylandEnable=false

HaltCommand=/sbin/shutdown -p now
RebootCommand=/sbin/shutdown -r now

# Enable automatic login for user
AutomaticLogin=ghostbsd
AutomaticLoginEnable=True

[security]

[xdmcp]

[greeter]

[chooser]

[debug]
# Uncomment the line below to turn on debugging
#Enable=true" > ${BASEDIR}/usr/local/etc/gdm/custom.conf

if [ "${PACK_PROFILE}" != "gnome" ] ; then
	rm ${BASEDIR}/usr/local/share/xsessions/gnome.desktop
fi

sed -i '' 's@#pcdm_enable="YES"@gdm_enable="YES"@g' ${BASEDIR}/etc/rc.conf