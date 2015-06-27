#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: cleandir.sh,v 1.2 2005/10/01 23:26:16 saturnero Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

echo "#### Removing build directories ####"

if [ -n "$(mount | grep ${BASEDIR}/var/run )" ] ; then
    umount -f ${BASEDIR}/var/run
fi

if [ -d "${BASEDIR}" ]; then
    chflags -R noschg ${BASEDIR}
    rm -rf ${BASEDIR}
fi

if [ -d "${CLONEDIR}" ]; then
    chflags -R noschg ${CLONEDIR}
    rm -rf ${CLONEDIR}
fi
