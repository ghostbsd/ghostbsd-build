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

jail_name=${PACK_PROFILE}${ARCH}

install_fetched_kernel()
{
echo "#### Installing kernel for ${ARCH} architecture ####" | tee -a ${LOGFILE}
cd ${CACHEDIR}
tar -yxf kernel.txz -C ${BASEDIR} --exclude=\*\.symbols
}

install_fetched_kernel

# fix missing linker.hints from /boot/kernel
if [ "${ARCH}" = "i386" ] ; then
    chrootcmd="chroot ${BASEDIR} kldxref /boot/kernel /boot/modules"
    $chrootcmd
fi

set -e
cd $LOCALDIR
