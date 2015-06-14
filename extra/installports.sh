#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: installports.sh,v 1.4 2007/01/04 18:28:56 saturnero Exp $
#
# Remount the ports' tree under ${BASEDIR}/usr/ports and install ports
# listed in the INSTALL_PORTS variable in the usual category/portname
# form, e.g.: x11/nvidia-driver audio/emu10kx ...

set -e -u

if [ -z "${LOGFILE:-}" ]; then
	echo "This script can't run standalone."
	echo "Please use launch.sh to execute it."
	exit 1
fi

INSTALL_PORTS=${INSTALL_PORTS:-}

if [ ! -z "${INSTALL_PORTS}" ]; then
	echo "Mounting ports' tree in the livefs chroot"
	set +e
	if ! kldstat -v | grep -q nullfs; then
		if ! kldload nullfs; then
			echo "Cannot find nullfs support in kernel and cannot find the proper module, aborting"
			exit 1
		fi
	fi
	set -e

	mkdir -p ${BASEDIR}/usr/ports ${BASEDIR}/usr/src
	mount_nullfs ${PORTSDIR:-/usr/ports} ${BASEDIR}/usr/ports
	mount_nullfs ${SRCDIR:-/usr/src} ${BASEDIR}/usr/src
	mount_devfs none ${BASEDIR}/dev

	print_error_umount() {
		echo "Something went wrong, check errors!" >&2
		[ -n "${LOGFILE:-}" ] && \
			echo "Log saved on ${LOGFILE}" >&2
		umount_null
		kill $$ # XXX exit 1 won't work.
	}

	umount_null() {
		umount ${BASEDIR}/usr/ports;
		umount ${BASEDIR}/usr/src;
		umount ${BASEDIR}/dev;
	}

	trap "umount_null; exit 1" INT

	tmpmakeconf=$(TMPDIR=${BASEDIR}/tmp mktemp -t make.conf)
	envvars="BATCH=true"
	if [ ! -z "${MAKE_CONF:-}" ]; then
		cat ${MAKE_CONF} > ${tmpmakeconf}
		envvars="${envvars} __MAKE_CONF=${tmpmakeconf#$BASEDIR}"
	fi
	
	for i in ${INSTALL_PORTS}; do
		echo "Compiling ${i}"
		(script -aq ${LOGFILE} chroot ${BASEDIR} make -C /usr/ports/${i} \
			${envvars} clean install clean || print_error_umount;) | grep '^===>'
	done

	umount_null
	trap "" INT
fi

cd ${LOCALDIR}
