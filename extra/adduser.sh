#!/bin/sh
#
# Copyright (c) 2011 Dario Freni
#
# See COPYRIGHT for licence terms.
#
# adduser.sh,v 1.5_1 Friday, January 14 2011 13:06:55

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

TMPFILE=$(mktemp -t adduser)

GHOSTBSD_ADDUSER="${GHOSTBSD_ADDUSER:-ghostbsd}"

# If directory /home exists, move it to /usr/home and do a symlink

if [ ! -d ${BASEDIR}/home ]; then
    mkdir -p ${BASEDIR}/home
fi

if [ ! -d ${BASEDIR}/home/${GHOSTBSD_ADDUSER} ]; then
    mkdir -p ${BASEDIR}/home/${GHOSTBSD_ADDUSER}
fi

set +e
grep -q ^${GHOSTBSD_ADDUSER}: ${BASEDIR}/etc/master.passwd

if [ $? -ne 0 ]; then
    chroot ${BASEDIR} pw useradd ${GHOSTBSD_ADDUSER} \
        -u 1000 -c "Live User" -d "/home/${GHOSTBSD_ADDUSER}" \
        -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
else
    chroot ${BASEDIR} pw usermod ${GHOSTBSD_ADDUSER} \
        -u 1000 -c "Live User" -d "/home/${GHOSTBSD_ADDUSER}" \
        -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
fi

chroot ${BASEDIR} pw mod user ${GHOSTBSD_ADDUSER} -w none

set -e

chown -R 1000:0 ${BASEDIR}/home/${GHOSTBSD_ADDUSER}

mkdir -p ${BASEDIR}/home/${GHOSTBSD_ADDUSER}/Desktop
chown -R 1000:0 ${BASEDIR}/home/${GHOSTBSD_ADDUSER}/Desktop


if [ -e ${BASEDIR}/usr/local/share/applications/ghostbsd-irc.desktop ] ; then
    cp -af ${BASEDIR}/usr/local/share/applications/ghostbsd-irc.desktop \
    ${BASEDIR}/home/${GHOSTBSD_ADDUSER}/Desktop
    chroot ${BASEDIR} chown -R 1000:0 /home/${GHOSTBSD_ADDUSER}/Desktop/ghostbsd-irc.desktop
    chroot ${BASEDIR} chmod +x /home/${GHOSTBSD_ADDUSER}/Desktop/ghostbsd-irc.desktop
fi