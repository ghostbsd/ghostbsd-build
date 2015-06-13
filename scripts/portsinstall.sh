#!/bin/sh
#
# Copyright 2010 GhostBSD
#
# See LICENSE for licence terms.
#
# $GhostBSD$
# $Id: pkginstall.sh,v 2.01 Tuesday, October 21 2014 Eric Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi


PKGFILE=${PKGFILE:-${LOCALDIR}/conf/ghostbsd};

if [ ! -f ${PKGFILE} ]; then
  return
fi

# Search main file package for include dependecies
# and build an depends file ( depends )
awk '/^ghostbsd_deps/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} | grep -v '"""' | grep -v '#' > ${LOCALDIR}/packages/depends

# If exist an old .packages file removes it
if [ -f ${LOCALDIR}/conf/ghostbsd ] ; then
  rm -f ${LOCALDIR}/conf/ghostbsd
fi

# Reads depends file and search for packages entries in each file from depends
# list, then append all packages found in ghostbsd file
while read pkgs ; do
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/ghostbsd.d/$pkgs  >> ${LOCALDIR}/conf/package
done < ${LOCALDIR}/packages/depends

# Removes """ and # from temporary package file
cat ${LOCALDIR}/conf/package | grep -v '"""' | grep -v '#' > ${LOCALDIR}/conf/ghostbsd

# Removes temporary files
if [ -f ${LOCALDIR}/conf/package ] ; then
  rm -f ${LOCALDIR}/conf/package
  rm -f ${LOCALDIR}/packages/depends
fi

PLOGFILE=".log_portsinstall"
cp -af ${PKGFILE} ${BASEDIR}/mnt
cp -af /etc/resolv.conf ${BASEDIR}/etc

cat > ${BASEDIR}/mnt/portsadded.sh << "EOF"
#!/bin/sh 

PLOGFILE=".log_portsinstall"
pkgfile="ghostbsd"
pkgaddcmd="pkg install -y "

cd /mnt
pkg update

while read pkgc; do
    if [ -n "${pkgc}" ] ; then
    echo "Installing settings from package $pkgc"
    echo "Running $pkgaddcmd ${pkgc}" >> ${PLOGFILE} 2>&1
    $pkgaddcmd $pkgc >> ${PLOGFILE} 2>&1
    fi
done < $pkgfile

rm /mnt/portsadded.sh
rm $pkgfile
rm /etc/resolv.conf

EOF

chrootcmd="chroot ${BASEDIR} sh /mnt/portsadded.sh"

$chrootcmd

# removes ghostbsd local repo
rm -Rf ${BASEDIR}/ghostbsd 
rm -f ${BASEDIR}/usr/local/etc/pkg/repos/GhostBSD.cfg

mv ${BASEDIR}/mnt/${PLOGFILE} /usr/obj/${LOCALDIR}

#umount ${BASEDIR}/var/run