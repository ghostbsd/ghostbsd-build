#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: installworld.sh,v 1.8 2006/06/11 18:29:50 saturnero Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

install_built_world()
{
echo "#### Installing world for ${ARCH} architecture ####"

# Set MAKE_CONF variable if it's not already set.
if [ -z "${MAKE_CONF:-}" ]; then
    if [ -n "${MINIMAL:-}" ]; then
	MAKE_CONF=${LOCALDIR}/conf/make.conf.minimal
    else
	MAKE_CONF=${LOCALDIR}/conf/make.conf
    fi
fi

cd ${SRCDIR}

makeargs="${MAKEOPT:-} ${MAKEJ_WORLD:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} DESTDIR=${BASEDIR} SRCCONF=${SRC_CONF}"
(env $MAKE_ENV script -aq $LOGFILE make ${makeargs:-} installworld || print_error;) | grep '^>>>'

makeargs="${MAKEOPT:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} DESTDIR=${BASEDIR} SRCCONF=${SRC_CONF}"
set +e
(env $MAKE_ENV script -aq $LOGFILE make ${makeargs:-} distribution || print_error;) | grep '^>>>'
}

install_fetched_freebsd()
{
echo "#### Installing world for ${ARCH} architecture ####"
if [ "${ARCH}" = "amd64" ]; then
    for files in base lib32 ; do
        cd $BASEDIR
        tar -yxf ${files}.txz -C ./
        rm -f ${files}.txz
    done
else 
    for files in base ; do
        cd $BASEDIR
        tar -yxf ${files}.txz -C ./
        rm -f ${files}.txz
    done
fi
}

if [ -n "${FETCH_FREEBSDBASE:-}" ]; then
    install_fetched_freebsd
else
    install_built_world
fi

set -e
cd $LOCALDIR
