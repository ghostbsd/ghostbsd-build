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

# If directory /home exists, move it to /usr/home and do a symlink

if [ ! -d ${BASEDIR}/home ]; then
    mkdir -p ${BASEDIR}/home
fi

if [ ! -d ${BASEDIR}/home/${GHOSTBSD_USER} ]; then
    mkdir -p ${BASEDIR}/home/${GHOSTBSD_USER}
fi

set +e
grep -q ^${GHOSTBSD_USER}: ${BASEDIR}/etc/master.passwd

if [ $? -ne 0 ]; then
    chroot ${BASEDIR} pw useradd ${GHOSTBSD_USER} \
        -u 1000 -c "Live User" -d "/home/${GHOSTBSD_USER}" \
        -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
else
    chroot ${BASEDIR} pw usermod ${GHOSTBSD_USER} \
        -u 1000 -c "Live User" -d "/home/${GHOSTBSD_USER}" \
        -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
fi

chroot ${BASEDIR} pw mod user ${GHOSTBSD_USER} -w none

