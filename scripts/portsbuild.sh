#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# $GhostBSD$
# $Id: iso.sh,v 1.7 Thu Dec 15 18:08:31 AST 2011 Eric


if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

if [ ! -f "/usr/local/bin/git" ]; then
  echo "Install Git to fetch pkg from GitHub"
  exit 1
fi


# Compiling ghostbsd ports
if [ ! -d ${BASEDIR}/ports ]; then
  mkdir -p ${BASEDIR}/ports
fi

echo "# Downloading ghostbsd ports from GitHub #"
git clone https://github.com/GhostBSD/ports.git ${BASEDIR}/ports >/dev/null 2>&1
rm -Rf ${BASEDIR}/ports/.git
rm -Rf ${BASEDIR}/ports/net-mgmt

rm -f ${BASEDIR}/ports/README.md

if [ ! -d ${BASEDIR}/usr/ports ]; then
  mkdir -p ${BASEDIR}/usr/ports
fi

if [ ! -d ${BASEDIR}/ghostbsd/All ]; then
  mkdir -p ${BASEDIR}/ghostbsd/All
fi

if [ ! -d ${BASEDIR}/usr/local/etc/pkg/repos ]; then
  mkdir -p ${BASEDIR}/usr/local/etc/pkg/repos
fi

mount_nullfs /usr/ports ${BASEDIR}/usr/ports

cat > ${BASEDIR}/portsbuild.sh << "EOF"
#!/bin/sh


for port in $(find /ports/ -type d -depth 2)  ; do
    echo $port
    cd $port
    make
    make package
    cd work/pkg
    mv *txz /ghostbsd/All
    #rm -Rf $port
done

pkg repo /ghostbsd
rm -f /portsbuild.sh
EOF

if [ ! -d ${BASEDIR}/usr/local/etc/pkg/repos ]; then
    mkdir -p ${BASEDIR}/usr/local/etc/pkg/repos
fi

cat > ${BASEDIR}/usr/local/etc/pkg/repos/GhostBSD.conf << "EOF"
# To disable this repository, instead of modifying or removing this file,
# create a /usr/local/etc/pkg/repos/GhostBSD.conf file:
#
#   echo "GhostBSD: { enabled: no }" > /usr/local/etc/pkg/repos/GhostBSD.conf

GhostBSD: {
  url: "file:/ghostbsd",
  mirror_type: "srv",
  enabled: yes
}
EOF

chrootcmd="chroot ${BASEDIR} sh /portsbuild.sh"

$chrootcmd

chrootcmd="chroot ${BASEDIR} pkg update"

$chrootcmd

rm -Rf ${BASEDIR}/ports
umount ${BASEDIR}/usr/ports
