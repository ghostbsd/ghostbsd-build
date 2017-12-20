#!/bin/sh
#
# Copyright (c) 2009 GhostBSD
#
# See COPYING for licence terms.
#
# $GhostBSD$
# $Id: buildworld.sh,v 1.8 Wednesday, December 07 2011 21:09 Eric Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi


fetch_freebsd()
{
mkdir -p /$CACHEDIR
echo "#### Fetching world for ${ARCH} architecture ####" | tee -a ${LOGFILE}
if [ "${ARCH}" = "amd64" ]; then
    for files in $AMD64_COMPONENTS ; do
        if [ ! -f $CACHEDIR/$files.txz ]; then
            cd $CACHEDIR
            fetch ${FETCH_LOCATION}/${files}.txz
        fi
    done
else
    for files in $I386_COMPONENTS ; do
        if [ ! -f $CACHEDIR/$files.txz ]; then
            cd $CACHEDIR
            fetch ${FETCH_LOCATION}/${files}.txz
        fi
    done
fi
}

mkdir -p ${BASEDIR}

fetch_freebsd

set -e
cd $LOCALDIR
