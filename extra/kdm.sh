#!/bin/sh
#
# Copyright (c) 2015 GhostBSD
#
# See COPYING for license terms.
#
# dm.sh,v 0.1

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi


set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

sed -i '' 's@#gdm_enable="YES"@kdm_enable="YES"@g' ${BASEDIR}/etc/rc.conf
