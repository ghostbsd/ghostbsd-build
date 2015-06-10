#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: installkernel.sh,v 1.8 2006/10/01 12:00:47 drizzt Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

echo "#### Installing kernel for ${ARCH} architecture ####"

# Set MAKE_CONF variable if it's not already set.
if [ -z "${MAKE_CONF:-}" ]; then
    if [ -n "${MINIMAL:-}" ]; then
	MAKE_CONF=${LOCALDIR}/conf/make.conf.minimal
    else
	MAKE_CONF=${LOCALDIR}/conf/make.conf
    fi
fi

if [ -n "${KERNELCONF:-}" ]; then
    export KERNCONFDIR=$(dirname ${KERNELCONF})
    export KERNCONF=$(basename ${KERNELCONF})
elif [ -z "${KERNCONF:-}" ]; then
    export KERNCONFDIR=${LOCALDIR}/conf/${ARCH}
    export KERNCONF="GENERIC"
fi

mkdir -p ${BASEDIR}/boot
cp ${SRCDIR}/sys/${ARCH}/conf/GENERIC.hints ${BASEDIR}/boot/device.hints
echo hint.psm.0.flags=0x1000 >> ${BASEDIR}/boot/device.hints
 
cd ${SRCDIR}

makeargs="${MAKEOPT:-} ${MAKEJ_KERNEL:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} DESTDIR=${BASEDIR} SRCCONF=${SRC_CONF}"
(env $MAKE_ENV script -aq $LOGFILE make ${makeargs:-} installkernel || print_error;) | grep '^>>>'

#cd ${BASEDIR}/boot/kernel
#if [ "${ARCH}" = "$(uname -p)" -a -z "${DEBUG:-}" ]; then
#    strip kernel
#fi

#gzip -f9 kernel

cd $LOCALDIR
