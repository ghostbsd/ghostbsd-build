#!/bin/sh
#
# Copyright (c) 2015 GhostBSD
#
# See COPYING for license terms.
#
# dm.sh,v 0.1

cp -rf extra/dm/default/* ${BASEDIR}/usr/local/share/PCDM/themes/default
cp -rf ${BASEDIR}/usr/local/share/backgrounds/ghostbsd/GreenLeaf.jpg ${BASEDIR}/usr/local/share/PCDM/themes/default/default.theme

sed -i.bak 's/${command} stop/# ${command} stop/g' ${BASEDIR}/usr/local/etc/rc.d/pcdm
