#!/bin/sh
#
# Wrapper to include configuration variables and invoke correct scripts
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for license terms.
#
# $FreeBSD$
# $Id: launch.sh,v 1.9 2006/10/01 12:00:47 drizzt Exp $
#
# Usage: launch.sh ${TARGET} [ ${LOGFILE} ]

set -e -u

if [ "`id -u`" != "0" ]; then
    echo "Sorry, this must be done as root."
    exit 1
fi

# If the GHOSTBSD_DEBUG environment variable is set, be verbose.
[ ! -z "${GHOSTBSD_DEBUG:-}" ] && set -x

# Set the absolute path for the toolkit dir
LOCALDIR=$(cd $(dirname $0)/.. && pwd)

CURDIR=$1;
shift;

TARGET=$1;
shift;

# Set LOGFILE. If it's a tmp file, schedule for deletion
if [ -n "${1:-}" ]; then
    LOGFILE=$1
    REMOVELOG=0
else
    LOGFILE=$(mktemp -q /tmp/ghostbsd.XXXXXX)
    REMOVELOG=1
fi

cd $CURDIR

. ./conf/ghostbsd.defaults.conf

GHOSTBSD_CONF=${GHOSTBSD_CONF:-./conf/ghostbsd.conf}

[ -f ${GHOSTBSD_CONF} ] && . ${GHOSTBSD_CONF}

# XXX set $ARCH and mandatory variables here.
if [ -z ${ARCH} ] 
then
ARCH=${ARCH:-`uname -p`}
fi

# Some variables can be passed to make only as environment, not as parameters.
# usage: env $MAKE_ENV make $makeargs
MAKE_ENV=${MAKE_ENV:-}

if [ ! -z ${MAKEOBJDIRPREFIX:-} ]; then
    MAKE_ENV="$MAKE_ENV MAKEOBJDIRPREFIX=${MAKEOBJDIRPREFIX}"
fi

report_error() {
    if [ ! -z ${GHOSTBSD_ERROR_MAIL:-} ]; then
	cat ${LOGFILE} | \
	    mail -s "GhostBSD build error in ${TARGET} phase" \
	    ${GHOSTBSD_ERROR_MAIL}
    fi
}

print_error() {
    echo "Something went wrong, check errors!" >&2
    [ -n "${LOGFILE:-}" ] && \
	echo "Log saved on ${LOGFILE}" >&2
    report_error
    kill $$ # XXX exit 1 won't work.
}

# If SCRIPTS_OVERRIDE is not defined, set it to ${LOCALDIR}/scripts/custom
SCRIPTS_OVERRIDE=${SCRIPTS_OVERRIDE:-"${LOCALDIR}/scripts/custom"}

# Check order:
#  - ${SCRIPTS_OVERRIDE}/${ARCH}/${TARGET}.sh
#  - ${SCRIPTS_OVERRIDE}/${TARGET}.sh
#  - scripts/${ARCH}/${TARGET}.sh
#  - scripts/${TARGET}.sh

if [ -f "${SCRIPTS_OVERRIDE}/${ARCH}/${TARGET}.sh" ]; then
    . ${SCRIPTS_OVERRIDE}/${ARCH}/${TARGET}.sh
elif [ -f "${SCRIPTS_OVERRIDE}/${TARGET}.sh" ]; then
    . ${SCRIPTS_OVERRIDE}/${TARGET}.sh
elif [ -f "${LOCALDIR}/scripts/${ARCH}/${TARGET}.sh" ]; then
    . ${LOCALDIR}/scripts/${ARCH}/${TARGET}.sh
elif [ -f "${LOCALDIR}/scripts/${TARGET}.sh" ]; then
    . ${LOCALDIR}/scripts/${TARGET}.sh
fi

[ $? -ne 0 ] && report_error

if [ ${REMOVELOG} -eq 1 ]; then
    rm -f ${LOGFILE}
fi
