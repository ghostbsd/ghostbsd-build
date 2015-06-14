#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: extra.sh,v 1.2 2005/10/01 23:26:16 saturnero Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

if [ -z "${EXTRA:-}" ]; then
    # No plugins selected, return with no errors
    return
fi

echo "#### Running plugins ####"

for plugin in ${EXTRA}; do
    echo "-> ${plugin}"
    if [ -f "${LOCALDIR}/extra/${ARCH}/${plugin}.sh" ]; then
	. ${LOCALDIR}/extra/${ARCH}/${plugin}.sh
    elif [ -f "${LOCALDIR}/extra/${plugin}.sh" ]; then
	. ${LOCALDIR}/extra/${plugin}.sh
    else
	echo "No ${plugin}.sh in ${LOCALDIR}/extra/${ARCH}/"
	echo "or ${LOCALDIR}/extra/, skipping"
	sleep 3
    fi
    if [ -d ${BASEDIR}/usr/ports/Mk ] ; then
        rm -Rf ${BASEDIR}/usr/ports/*
    fi
    if [ -n "$(mount | grep ${BASEDIR}/var/run)" ]; then
        umount ${BASEDIR}/var/run
    fi
done

