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

JAILFS=$(echo ${BASEDIR} | cut -d / -f 3,3)
jail_name=${JAILFS}${PACK_PROFILE}${ARCH}

echo "#### Running plugins ####"

if ! ${USE_JAILS} ; then
    if [ -z "$(mount | grep ${BASEDIR}/var/run)" ]; then
        mount_nullfs /var/run ${BASEDIR}/var/run
    fi
fi


# copy to jail resolv.conf
cp -af /etc/resolv.conf ${BASEDIR}/etc/resolv.conf

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
done

if [ -d ${BASEDIR}/dist/ports/Mk ] ; then
    rm -f ${BASEDIR}/usr/ports
    mkdir -p ${BASEDIR}/usr/ports
    if [ -f "${BASEDIR}/pdevice" ]; then
        PDEVICE=$(cat ${BASEDIR}/pdevice)
        if [ -c "/dev/${PDEVICE}" ]; then
            umount -f /dev/${PDEVICE}
            mdconfig -d -u ${PDEVICE}
        fi
    fi
    rm -f ${BASEDIR}/ports.ufs
    rm -f ${BASEDIR}/pdevice
fi

if ! ${USE_JAILS}; then
    if [ -n "$(mount | grep ${BASEDIR}/var/run)" ]; then
        umount ${BASEDIR}/var/run
    fi
else
    service jail onestop $jail_name
fi

# removes from jail resolv.conf
rm -f ${BASEDIR}/etc/resolv.conf

