#!/bin/sh
#
# Copyright (c) Matteo Riondato
#
# See COPYING for licence terms.
#
# $Id: xautostart.sh,v 1.1 2007/01/16 08:19:46 rionda Exp $
# 

set -e -u

if [ -z "${LOGFILE:-}" ]; then
	echo "This script can't run standalone."
	echo "Please use launch.sh to execute it."
	exit 1
fi

mkdir -p $BASEDIR/mnt $BASEDIR/etc/rc.d/ $BASEDIR/usr/local/sbin/

cp extra/xautostart/xautostart.rc $BASEDIR/etc/rc.d/xautostart
chmod 555 $BASEDIR/etc/rc.d/xautostart

