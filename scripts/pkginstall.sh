#!/bin/sh
#
# Copyright 2010 GhostBSD
#
# See LICENSE for licence terms.
#
# $GhostBSD$
# $Id: pkginstall.sh,v 2.01 Tuesday, October 21 2014 Eric Exp $

# set -e -u
set -u

if [ -z "${LOGFILE:-}" ]; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

PKGFILE=${PKGFILE:-/tmp/${PACK_PROFILE}-packages};

#if [ ! -f ${PKGFILE} ]; then
 # return
#fi
touch ${PKGFILE}

# Search main file package for include dependecies
# and build an depends file ( depends )
awk '/^deps/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} | grep -v '"""' | grep -v '#' > /tmp/${PACK_PROFILE}-depends

# If exist an old .packages file removes it
if [ -f /tmp/${PACK_PROFILE}-packages ] ; then
  rm -f /tmp/${PACK_PROFILE}-packages
fi

set +e
# Reads packages from packages profile
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} > /tmp/${PACK_PROFILE}-package

# Reads depends file and search for packages entries in each file from depends
# list, then append all packages found in packages file
while read pkgs ; do
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/packages.d/$pkgs  >> /tmp/${PACK_PROFILE}-package
done < /tmp/${PACK_PROFILE}-depends

# Removes """ and # from temporary package file
cat /tmp/${PACK_PROFILE}-package | grep -v '"""' | grep -v '#' > /tmp/${PACK_PROFILE}-packages

# Reads depends file and search for settings entries in each file from depends
# list, then append all packages found in packages file
while read pkgs ; do
awk '/^settings/,/^"""/' ${LOCALDIR}/packages/packages.d/$pkgs  >> /tmp/${PACK_PROFILE}-setting
done < /tmp/${PACK_PROFILE}-depends

# search for $ARCH specific packages if an $ARCH section is found in each file from depends
# lost, then append all packages found in packages file
while read pkgs ; do
awk '/^'${ARCH}'/,/^"""/' ${LOCALDIR}/packages/packages.d/$pkgs  >> /tmp/${PACK_PROFILE}-package
done < /tmp/${PACK_PROFILE}-depends

# Removes """ and # from temporary package file
cat /tmp/${PACK_PROFILE}-package | grep -v '"""' | grep -v '#' > /tmp/${PACK_PROFILE}-packages

# Removes """ and # from temporary package file
set +e
cat /tmp/${PACK_PROFILE}-setting | grep -v '"""' | grep -v '#'
if [ $? -ne 0 ] ; then
  else
cat /tmp/${PACK_PROFILE}-setting | grep -v '"""' | grep -v '#' > /tmp/${PACK_PROFILE}-settings
fi

set -e
# Removes temporary/leftover files
if [ -f /tmp/${PACK_PROFILE}-package ] ; then
  rm -f /tmp/${PACK_PROFILE}-package
  rm -f /tmp/${PACK_PROFILE}-depends
  rm -f /tmp/${PACK_PROFILE}-setting
fi

set -e

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

#sed -i '' 's@signature_type: "fingerprints"@#signature_type: "fingerprints"@g' ${BASEDIR}/etc/pkg/FreeBSD.conf

#sed -i '' 's@url: "pkg+http://pkg.FreeBSD.org/${ABI}/quarterly"@url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest"@g' ${BASEDIR}/etc/pkg/FreeBSD.conf

if [ ! -d "${BASEDIR}/usr/local/etc/pkg/repos" ] ; then
  mkdir -p ${BASEDIR}/usr/local/etc/pkg/repos
fi

echo "FreeBSD: { enabled: no }" > ${BASEDIR}/usr/local/etc/pkg/repos/FreeBSD.conf

echo "GhostBSD: {
  url: \"http://pkg.GhostBSD.org/GhostBSD-11/${ARCH}/current\",
  enabled: yes
}
" > ${BASEDIR}/etc/pkg/GhostBSD.conf
sync
sync
sleep 9


mkdir -p ${PACKCACHEDIR}
mkdir -p ${BASEDIR}/var/cache/pkg

filled=$(ls ${PACKCACHEDIR})

if [ -z "$filled" ] ; then
# prepares addpkg.sh script to add packages under chroot
cat > ${BASEDIR}/mnt/addpkg.sh << "EOF"
#!/bin/sh

FORCE_PKG_REGISTER=true
export FORCE_PKG_REGISTER

#ln -sf /dist/ports /usr/ports

# pkg bootstrap with env
env ASSUME_ALWAYS_YES=YES pkg bootstrap -f

# pkg install part
cd /mnt
PLOGFILE=".log_pkginstall"
pkgfile="${PACK_PROFILE}-packages"
pkgaddcmd="pkg install -y "

while read pkgc; do
  if [ -n "${pkgc}" ] ; then
    echo "Installing package $pkgc"
    echo "Running $pkgaddcmd ${pkgc}" >> ${PLOGFILE} 2>&1
    pkg unlock -q -y $pkgc
    if [ "${pkgc}" = "bsdstats" ] ; then
      BATCH=yes $pkgaddcmd $pkgc >> ${PLOGFILE} 2>&1
    else
      $pkgaddcmd $pkgc >> ${PLOGFILE} 2>&1
    fi
    if [ $? -ne 0 ] ; then
      echo "$pkgc not found in repos" >> ${PLOGFILE} 2>&1
      echo "$pkgc not found in repos"
      exit 1
    fi
    # prevent removal of pkglist files
    # this end up to not being able to update.
    # pkg lock -q -y $pkgc
  fi
done < $pkgfile

# deactivate  bsdstats_enable from rc.conf
if [ -f /etc/rc.conf ] ; then
  grep -q "bsdstats_enable" /etc/rc.conf
  if [ $? -eq 0 ] ; then
    sed -i '' "/bsdstats_enable*/d" /etc/rc.conf
  fi
fi
rm addpkg.sh
rm $pkgfile
# clean cachedir
echo "Cleaning cachedir"
echo "Cleaning cachedir" >> ${PLOGFILE} 2>&1
pkg clean -y
EOF

# run addpkg.sh in chroot to add packages
chrootcmd="chroot ${BASEDIR} sh /mnt/addpkg.sh"
$chrootcmd

rsync -aI ${BASEDIR}/var/cache/pkg/*.txz  ${PACKCACHEDIR}/
else
rsync -aI ${PACKCACHEDIR}/*txz  ${BASEDIR}/var/cache/pkg/
cat > ${BASEDIR}/mnt/addpkg.sh << "EOF"
#!/bin/sh

FORCE_PKG_REGISTER=true
export FORCE_PKG_REGISTER

#ln -sf /dist/ports /usr/ports

# pkg bootstrap with env
env ASSUME_ALWAYS_YES=YES pkg bootstrap -f

# pkg install part
cd /mnt
PLOGFILE=".log_pkginstall"
pkgfile="${PACK_PROFILE}-packages"
pkgaddcmd="pkg install -y "

while read pkgc; do
  if [ -n "${pkgc}" ] ; then
    echo "Installing package $pkgc"
    echo "Running $pkgaddcmd ${pkgc}" >> ${PLOGFILE} 2>&1
    pkg unlock -q -y $pkgc
    if [ "${pkgc}" = "bsdstats" ] ; then
      BATCH=yes $pkgaddcmd $pkgc >> ${PLOGFILE} 2>&1
    else
    $pkgaddcmd $pkgc >> ${PLOGFILE} 2>&1
    fi
    if [ $? -ne 0 ] ; then
      echo "$pkgc not found in repos" >> ${PLOGFILE} 2>&1
      echo "$pkgc not found in repos"
      exit 1
    fi
    # prevent removal of pkglist files
    # this end up to not being able to update.
    #pkg lock -q -y $pkgc
  fi
done < $pkgfile

# deactivate  bsdstats_enable from rc.conf
if [ -f /etc/rc.conf ] ; then
  grep -q "bsdstats_enable" /etc/rc.conf
  if [ $? -eq 0 ] ; then
    sed -i '' "/bsdstats_enable*/d" /etc/rc.conf
  fi
fi
rm addpkg.sh
rm $pkgfile
# clean cachedir
echo "Cleaning cachedir"
echo "Cleaning cachedir" >> ${PLOGFILE} 2>&1
pkg clean -y
EOF

# run addpkg.sh in chroot to add packages
chrootcmd="chroot ${BASEDIR} sh /mnt/addpkg.sh"
$chrootcmd

fi

sed -i '' 's@#signature_type: "fingerprints"@signature_type: "fingerprints"@g' ${BASEDIR}/etc/pkg/FreeBSD.conf

mv ${BASEDIR}/mnt/${PLOGFILE} ${MAKEOBJDIRPREFIX}/${LOCALDIR}

if ! ${USE_JAILS} ; then
    if [ -n "$(mount | grep ${BASEDIR}/var/run)" ]; then
        umount ${BASEDIR}/var/run
    fi
fi

rm ${BASEDIR}/etc/resolv.conf
