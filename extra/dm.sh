#!/bin/sh
#
# Copyright (c) 2015 GhostBSD
#
# See COPYING for license terms.
#
# dm.sh,v 0.1

cp -rf extra/dm/default/* ${BASEDIR}/usr/local/share/PCDM/themes/default
cp -rf ${BASEDIR}/usr/local/share/backgrounds/ghostbsd/GreenLeaf.jpg ${BASEDIR}/usr/local/share/PCDM/themes/default/background.jpg

sed -i.bak 's/${command} stop/# ${command} stop/g' ${BASEDIR}/usr/local/etc/rc.d/pcdm

# Auto login for user ghostbsd.
sed -i.bak 's/ENABLE_AUTO_LOGIN=FALSE/ENABLE_AUTO_LOGIN=TRUE/g' ${BASEDIR}/usr/local/etc/rc.d/pcdm
sed -i.bak 's/AUTO_LOGIN_USER=no-username/AUTO_LOGIN_USER=ghostbsd/g' ${BASEDIR}/usr/local/etc/rc.d/pcdm