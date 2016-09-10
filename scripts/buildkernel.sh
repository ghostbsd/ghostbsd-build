#!/bin/sh
#
# Copyright (c) 2009-2011 GhostBSD
#
# See COPYING for licence terms.
#
# $GhostBSD$
# $Id: buildkernel.sh,v 1.8 Wednesday, December 07 2011 21:09 Eric Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

fetch_kernel()
{
echo "#### Fetching kernel for ${ARCH} architecture ####" | tee -a ${LOGFILE}
mkdir -p $CACHEDIR
cd $CACHEDIR
if [ ! -f $CACHEDIR/kernel.txz ]; then
    fetch ${FETCH_LOCATION}/kernel.txz
fi
}

build_kernel()
{
echo "#### Building kernel for ${ARCH} architecture ####"

if [ -n "${NO_BUILDKERNEL:-}" ]; then
    echo "NO_BUILDKERNEL set, skipping build" | tee -a ${LOGFILE}
    return
fi

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

cd $SRCDIR

unset EXTRA

makeargs="${MAKEOPT:-} ${MAKEJ_KERNEL:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} SRCCONF=${SRC_CONF}"
(env $MAKE_ENV script -aq $LOGFILE make $makeargs buildkernel || print_error;) | grep '^>>>'
}

if [ -n "${FETCH_FREEBSDKERNEL:-}" ]; then
    fetch_kernel
else
    build_kernel
fi

set -e
cd $LOCALDIR

