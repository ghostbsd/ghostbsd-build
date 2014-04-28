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

if [ ! -L ${BASEDIR}/home -a -d ${BASEDIR}/home ]; then
  mv ${BASEDIR}/home ${BASEDIR}/usr/home

fi


if [ ! -d ${BASEDIR}/usr/home ]; then
  mkdir -p ${BASEDIR}/usr/home
fi

if [ ! -d ${BASEDIR}/usr/home/${GHOSTBSD_USER} ]; then

    mkdir -p ${BASEDIR}/usr/home/${GHOSTBSD_USER}

fi

set +e
grep -q ^${GHOSTBSD_USER}: ${BASEDIR}/etc/master.passwd

if [ $? -ne 0 ]; then
    chroot ${BASEDIR} pw useradd ${GHOSTBSD_USER} \
        -u 1000 -c "GhostBSD User" -d "/home/${GHOSTBSD_USER}" \
        -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
else
    chroot ${BASEDIR} pw usermod ${GHOSTBSD_USER} \
        -u 1000 -c "GhostBSD User" -d "/home/${GHOSTBSD_USER}" \
        -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
fi

# fish shell for live root.
#chroot ${BASEDIR} chsh -s /usr/local/bin/fish root 
    
set -e

chown -R 1000:0 ${BASEDIR}/home/${GHOSTBSD_USER}

if [ ! -z "${NO_UNIONFS:-}" ]; then
    echo "Adding init script for /home mfs"

    cp ${LOCALDIR}/extra/adduser/homemfs.rc ${BASEDIR}/etc/rc.d/homemfs
    chmod 555 ${BASEDIR}/etc/rc.d/homemfs

    echo "Saving mtree structure for /home/"

    mtree -Pcp ${BASEDIR}/usr/home > ${TMPFILE}
    mv ${TMPFILE} ${BASEDIR}/etc/mtree/home.dist
fi
