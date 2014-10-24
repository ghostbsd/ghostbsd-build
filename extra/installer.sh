#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# installer.sh, v1.3 Sunday, June 29 2014, Eric Turgeon
#
set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

# Installer backend.
if [ ! -d ${BASEDIR}/pdbsd ]; then
  git clone https://github.com/pcbsd/pcbsd.git ${BASEDIR}/pcbsd
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /pcbsd/src-sh/pc-sysinstall
sh install.sh
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh 
rm -rf ${BASEDIR}/pcbsd


if [ ! -d ${BASEDIR}/usr/local/etc/gbi ]; then
    mkdir -p ${BASEDIR}/usr/local/etc/gbi
fi

## put the installer in the system
cp -Rf extra/installer/gbi/ ${BASEDIR}/usr/local/etc/gbi

## put the installer on the desktop
cp -pf extra/installer/GBI.desktop ${BASEDIR}${HOME}/Desktop/
chown -R 1000:0 ${BASEDIR}${HOME}/Desktop/GBI.desktop


# copy gbi script to /usr/local/bin.
install -C extra/installer/gbi.sh ${BASEDIR}/usr/local/bin/gbi



