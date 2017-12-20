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

fetch_kernel

set -e
cd $LOCALDIR

