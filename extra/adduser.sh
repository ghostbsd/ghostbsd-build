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

if [ ! -L ${BASEDIR}/usr/home ]; then
    ln -s ${BASEDIR}/home ${BASEDIR}/usr/home
fi


set +e
grep -q ^${GHOSTBSD_ADDUSER}: ${BASEDIR}/etc/master.passwd

if [ $? -ne 0 ]; then
    chroot ${BASEDIR} pw useradd ${GHOSTBSD_ADDUSER} \
        -u 1000 -c "GhostBSD User" -d "/home/${GHOSTBSD_ADDUSER}" \
        -g 0 -G 5 -m -s /bin/csh -k /usr/share/skel -w none
else
    chroot ${BASEDIR} pw usermod ${GHOSTBSD_ADDUSER} \
        -u 1000 -c "GhostBSD User" -d "/usr/home/${GHOSTBSD_ADDUSER}" \
        -g 0 -G 5 -m -s /bin/csh -k /usr/share/skel -w none
fi

chroot ${BASEDIR} pw group mod wheel operator -m ${GHOSTBSD_ADDUSER}
chroot ${BASEDIR} pw mod user ${GHOSTBSD_ADDUSER} -w none

set -e

chown -R 1000:0 ${BASEDIR}/usr/home/${GHOSTBSD_ADDUSER}

if [ ! -z "${NO_UNIONFS:-}" ]; then
    echo "Adding init script for /home mfs"

    cp ${LOCALDIR}/extra/adduser/homemfs.rc ${BASEDIR}/etc/rc.d/homemfs
    chmod 555 ${BASEDIR}/etc/rc.d/homemfs

    echo "Saving mtree structure for /home/"

    mtree -Pcp ${BASEDIR}/usr/home > ${TMPFILE}
    mv ${TMPFILE} ${BASEDIR}/etc/mtree/home.dist
fi
