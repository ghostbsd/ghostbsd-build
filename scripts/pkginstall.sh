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

PKGFILE=${PKGFILE:-${LOCALDIR}/conf/${PACK_PROFILE}-packages};

#if [ ! -f ${PKGFILE} ]; then
 # return
#fi
touch ${PKGFILE}

# Search main file package for include dependecies
# and build an depends file ( depends )
awk '/^deps/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} | grep -v '"""' | grep -v '#' > ${LOCALDIR}/packages/${PACK_PROFILE}-depends

# If exist an old .packages file removes it
if [ -f ${LOCALDIR}/conf/${PACK_PROFILE}-packages ] ; then
  rm -f ${LOCALDIR}/conf/${PACK_PROFILE}-packages
fi

# Reads packages from packages profile
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} > ${LOCALDIR}/conf/${PACK_PROFILE}-package

# Reads depends file and search for packages entries in each file from depends
# list, then append all packages found in packages file
while read pkgs ; do
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/packages.d/$pkgs  >> ${LOCALDIR}/conf/${PACK_PROFILE}-package
done < ${LOCALDIR}/packages/${PACK_PROFILE}-depends 

# Removes """ and # from temporary package file
cat ${LOCALDIR}/conf/${PACK_PROFILE}-package | grep -v '"""' | grep -v '#' > ${LOCALDIR}/conf/${PACK_PROFILE}-packages

# Removes temporary/leftover files
if [ -f ${LOCALDIR}/conf/${PACK_PROFILE}-package ] ; then
  rm -f ${LOCALDIR}/conf/${PACK_PROFILE}-package
  rm -f ${LOCALDIR}/packages/${PACK_PROFILE}-depends
fi

for left_files in ports ghostbsd pcbsd gbi ; do
    rm -Rf ${BASEDIR}/${left_files}
done

if [ -f ${BASEDIR}/usr/local/etc/repos/GhostBSD.conf ]; then
    rm -f  ${BASEDIR}/usr/local/etc/repos/GhostBSD.conf
fi

#mounts ${BASEDIR}/var/run because it's needed when building ports in chroot
if ! $USE_JAILS; then
    if [ -z "$(mount | grep ${BASEDIR}/var/run)" ]; then
        mount_nullfs /var/run ${BASEDIR}/var/run
    fi
fi
cp /etc/resolv.conf ${BASEDIR}/etc/resolv.conf

PLOGFILE=".log_pkginstall"
echo "Installing packages listed in ${PKGFILE}"

# cp resolv.conf for fetching packages
cp $PKGFILE ${BASEDIR}/mnt

sed -i '' 's@signature_type: "fingerprints"@#signature_type: "fingerprints"@g' ${BASEDIR}/etc/pkg/FreeBSD.conf

# prepares ports tree
portsnap fetch
portsnap extract -p ${BASEDIR}/usr/ports

# prepares addpkg.sh script to add packages under chroot
cat > ${BASEDIR}/mnt/addpkg.sh << "EOF"
#!/bin/sh 

FORCE_PKG_REGISTER=true
export FORCE_PKG_REGISTER

# builds pkg from ports to avoid Y/N question
cd /usr/ports/ports-mgmt/pkg
make deinstall
make
make install

# pkg install part
cd /mnt
PLOGFILE=".log_pkginstall"
pkgfile="${PACK_PROFILE}-packages"
pkgaddcmd="pkg install -y "

while read pkgc; do
    if [ -n "${pkgc}" ] ; then
    echo "Installing package $pkgc"
    echo "Running $pkgaddcmd ${pkgc}" >> ${PLOGFILE} 2>&1
    $pkgaddcmd $pkgc >> ${PLOGFILE} 2>&1
    fi
done < $pkgfile

rm addpkg.sh
rm $pkgfile
EOF

# run addpkg.sh in chroot to add packages
chrootcmd="chroot ${BASEDIR} sh /mnt/addpkg.sh"
$chrootcmd


sed -i '' 's@#signature_type: "fingerprints"@signature_type: "fingerprints"@g' ${BASEDIR}/etc/pkg/FreeBSD.conf

mv ${BASEDIR}/mnt/${PLOGFILE} ${MAKEOBJDIRPREFIX}/${LOCALDIR}

if ! ${USE_JAILS} ; then
    if [ -n "$(mount | grep ${BASEDIR}/var/run)" ]; then
        umount ${BASEDIR}/var/run
    fi
fi
rm ${BASEDIR}/etc/resolv.conf
