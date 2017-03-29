#!/bin/sh
#
# Copyright (c) 2015 Angelescu Ovidiu
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: installports.sh,v 1.5 2015/08/19 18:28:56 convbsd Exp $
#
# Install ports listed in the INSTALL_PORTS variable
# in the usual category/portname
# form, e.g.: x11/nvidia-driver audio/emu10kx ...

set -e -u

if [ -z "${LOGFILE:-}" ]; then
	echo "This script can't run standalone."
	echo "Please use launch.sh to execute it."
	exit 1
fi

INSTALL_PORTS=${INSTALL_PORTS:-}

if ! ${USE_JAILS} ; then
    if [ -z "$(mount | grep ${BASEDIR}/var/run)" ]; then
        mount ${BASEDIR}/var/run
    fi
fi

cp /etc/resolv.conf ${BASEDIR}/etc/resolv.conf

if [ ! -z "${INSTALL_PORTS}" ]; then
	tmpmakeconf=$(TMPDIR=${BASEDIR}/tmp mktemp -t make.conf)
	envvars="BATCH=true"
	if [ ! -z "${MAKE_CONF:-}" ]; then
		cat ${MAKE_CONF} > ${tmpmakeconf}
		envvars="${envvars} __MAKE_CONF=${tmpmakeconf#$BASEDIR}"
	fi

	for i in ${INSTALL_PORTS}; do
		echo "Compiling ${i}"
		(script -aq ${LOGFILE} chroot ${BASEDIR} make -C /usr/ports/${i} \
			${envvars} clean reinstall clean;) | grep '^===>'
	done
fi

if ! ${USE_JAILS} ; then
    if [ -n "$(mount | grep ${BASEDIR}/var/run)" ]; then
        umount ${BASEDIR}/var/run
    fi
fi

rm -f ${BASEDIR}/etc/resolv.conf

cd ${LOCALDIR}
