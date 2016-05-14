#!/bin/sh
#
# Copyright (c) 2015 GhostBSD
#
# See COPYING for license terms.
#
# dm.sh,v 0.1

cp -f ${BASEDIR}/usr/local/share/backgrounds/ghostbsd/Frosted_Leaf.jpg ${BASEDIR}/usr/local/share/slim/themes/background.jpg
cp -f ${BASEDIR}/usr/local/share/backgrounds/ghostbsd/Frosted_Leaf.jpg ${BASEDIR}/usr/local/share/slim/themes/default/background.jpg

# sed -i "" 's/${command} stop/# ${command} stop/g' ${BASEDIR}/usr/local/etc/rc.d/pcdm
echo 'exec $1' >> ${BASEDIR}/home/ghostbsd/.xinitrc

# default user for ghostbsd.
sed -i "" "s/\#default_user/default_user/g" ${BASEDIR}/usr/local/etc/slim.conf
sed -i "" "s/simone/ghostbsd/g" ${BASEDIR}/usr/local/etc/slim.conf
