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

PKGFILE=${PKGFILE:-${LOCALDIR}/conf/packages};

if [ ! -f ${PKGFILE} ]; then
  return
fi



if [ "$(uname -p)" != "amd64" ]; then
  echo "----------------------------------------------------------"
  echo "You can install packages for i386 architecture"
  echo "only if your machine architecture is amd64"
  echo "----------------------------------------------------------"
  echo "Skipping package installation."
  echo "----------------------------------------------------------"
  sleep 5 
  return
else
  echo "----------------------------------------------------------"
  echo "You can install packages for i386 architecture"
  echo "only if your machine architecture is amd64"
  echo "----------------------------------------------------------"
  echo "Starting package installation."
  echo "----------------------------------------------------------"
  sleep 5
fi

# Search main file package for include dependecies
# and build an depends file ( depends )
awk '/^deps/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} | grep -v '"""' | grep -v '#' > ${LOCALDIR}/packages/depends

# Search main file package for included settings
# and build a settings file 
#awk '/^settings/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} | grep -v '"""' | grep -v '#' > ${LOCALDIR}/packages/settings

# Add to EXTRA plugins the needed plugin readed from settings section
# Readed plugin is added only if it isn't already in conf file
#add_extra=$(cat ${LOCALDIR}/packages/${PACK_PROFILE} | grep -iF1 settings= | grep -v '"""')

# If exist an old .packages file removes it
if [ -f ${LOCALDIR}/conf/packages ] ; then
  rm -f ${LOCALDIR}/conf/packages
fi

# Reads packages from packages profile
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} > ${LOCALDIR}/conf/package

# Reads depends file and search for packages entries in each file from depends
# list, then append all packages found in packages file
while read pkgs ; do
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/packages.d/$pkgs  >> ${LOCALDIR}/conf/package
done < ${LOCALDIR}/packages/depends 

# Removes """ and # from temporary package file
cat ${LOCALDIR}/conf/package | grep -v '"""' | grep -v '#' > ${LOCALDIR}/conf/packages

# Removes temporary files
if [ -f ${LOCALDIR}/conf/package ] ; then
  rm -f ${LOCALDIR}/conf/package
  rm -f ${LOCALDIR}/packages/depends
fi

PLOGFILE=".log_pkginstall"
echo "Installing packages listed in ${PKGFILE}"

# cp resolv.conf for fetching packages
cp /etc/resolv.conf ${BASEDIR}/etc
cp $PKGFILE ${BASEDIR}/mnt

sed -i '' 's@signature_type: "fingerprints"@#signature_type: "fingerprints"@g' ${BASEDIR}/etc/pkg/FreeBSD.conf

cat > ${BASEDIR}/mnt/addpkg.sh << "EOF"
#!/bin/sh 

cd /mnt
PLOGFILE=".log_pkginstall"
pkgfile="packages"
pkgaddcmd="pkg install -y "
/usr/sbin/pkg bootstrap -y

while read pkgc; do
    if [ -n "${pkgc}" ] ; then
    echo "Installing package $pkgc"
    echo "Running $pkgaddcmd ${pkgc}" >> ${PLOGFILE} 2>&1
    $pkgaddcmd $pkgc >> ${PLOGFILE} 2>&1
    fi
done < $pkgfile

rm addpkg.sh
rm $pkgfile
rm /etc/resolv.conf

EOF

chrootcmd="chroot ${BASEDIR} sh /mnt/addpkg.sh"

$chrootcmd

 
sed -i '' 's@#signature_type: "fingerprints"@signature_type: "fingerprints"@g' ${BASEDIR}/etc/pkg/FreeBSD.conf

mv ${BASEDIR}/mnt/${PLOGFILE} /usr/obj/${LOCALDIR}
