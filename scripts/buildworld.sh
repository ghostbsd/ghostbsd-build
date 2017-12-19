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

build_world()
{
echo "#### Building world for ${ARCH} architecture ####"

if [ -n "${NO_BUILDWORLD:-}" ]; then
    echo "NO_BUILDWORLD set, skipping build" | tee -a ${LOGFILE}
    return
fi

cd $SRCDIR

unset EXTRA

makeargs="${MAKEOPT:-} ${MAKEJ_WORLD:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} SRCCONF=${SRC_CONF}"
echo $makeargs
sleep 10
(env $MAKE_ENV script -aq $LOGFILE make ${makeargs:-} buildworld || print_error;) | grep '^>>>'
}

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

if [ -n "${FETCH_FREEBSDBASE:-}" ]; then
    fetch_freebsd
else
    build_world
fi

set -e
cd $LOCALDIR
