#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# $GhostBSD$
# $Id: gbsdports.sh,v 1.7 Thu Jun 23 10:04:31 AST 2015 Angelescu Ovidiu


if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

if [ ! -f "/usr/local/bin/git" ]; then
  echo "Install Git to fetch pkg from GitHub"
  exit 1
fi

PKGFILE=${PKGFILE:-${LOCALDIR}/conf/${PACK_PROFILE}-ghostbsd};

#if [ ! -f ${PKGFILE} ]; then
 # return
#fi
touch ${PKGFILE}

# Search main file package for include dependecies
# and build an depends file ( depends )
awk '/^ghostbsd_deps/,/^"""/' ${LOCALDIR}/packages/${PACK_PROFILE} | grep -v '"""' | grep -v '#' > ${LOCALDIR}/packages/${PACK_PROFILE}-gdepends

# If exist an old .packages file removes it
if [ -f ${LOCALDIR}/conf/${PACK_PROFILE}-ghostbsd ] ; then
  rm -f ${LOCALDIR}/conf/${PACK_PROFILE}-ghostbsd
fi

# Reads depends file and search for packages entries in each file from depends
# list, then append all packages found in ghostbsd file
while read pkgs ; do
awk '/^packages/,/^"""/' ${LOCALDIR}/packages/ghostbsd.d/$pkgs  >> ${LOCALDIR}/conf/${PACK_PROFILE}-gpackage
done < ${LOCALDIR}/packages/${PACK_PROFILE}-gdepends

# Removes """ and # from temporary package file
cat ${LOCALDIR}/conf/${PACK_PROFILE}-gpackage | grep -v '"""' | grep -v '#' > ${LOCALDIR}/conf/${PACK_PROFILE}-ghostbsd

# Removes temporary files
if [ -f ${LOCALDIR}/conf/${PACK_PROFILE}-gpackage ] ; then
  rm -f ${LOCALDIR}/conf/${PACK_PROFILE}-gpackage
  rm -f ${LOCALDIR}/packages/${PACK_PROFILE}-gdepends
fi

if ! ${USE_JAILS} ; then
    if [ -z "$(mount | grep ${BASEDIR}/var/run)" ]; then
        mount_nullfs /var/run ${BASEDIR}/var/run
    fi
fi
cp -af /etc/resolv.conf ${BASEDIR}/etc

# Compiling ghostbsd ports
if [ -d ${BASEDIR}/ports ]; then
  rm -Rf ${BASEDIR}/ports
fi
#mkdir -p ${BASEDIR}/usr/ports

echo "# Downloading ghostbsd ports from GitHub #"
git clone https://github.com/GhostBSD/ports.git ${BASEDIR}/ports >/dev/null 2>&1
cp -Rf $BASEDIR/ports/ $BASEDIR/dist/ports

# build ghostbsd ports 
cp -af ${PKGFILE} ${BASEDIR}/mnt
PLOGFILE=".log_portsinstall"

cat > ${BASEDIR}/mnt/portsbuild.sh << "EOF"
#!/bin/sh 

pkgfile="${PACK_PROFILE}-ghostbsd"
FORCE_PKG_REGISTER=true
export FORCE_PKG_REGISTER
PLOGFILE=".log_portsinstall"

cd /mnt

while read pkgc; do
    if [ -n "${pkgc}" ] ; then
        echo "Building and installing port $pkgc"
        # builds ghostbsd ports in chroot
        for port in $(find /ports/ -type d -depth 2 -name ${pkgc})  ; do
        cd $port
        make >> /mnt/${PLOGFILE} 2>&1 
        make install >> /mnt/${PLOGFILE} 2>&1 
        done
    fi
done < $pkgfile

rm -f /mnt/portsbuild.sh
rm -f /mnt/$pkgfile

EOF


# Build and install ghostbsd ports in chroot 
chrootcmd="chroot ${BASEDIR} sh /mnt/portsbuild.sh"
$chrootcmd

rm -Rf ${BASEDIR}/ports

# save logfile where should be
mv ${BASEDIR}/mnt/${PLOGFILE} ${MAKEOBJDIRPREFIX}/${LOCALDIR}

# umount /var/run if not using jails
if ! ${USE_JAILS} ; then
    if [ -n "$(mount | grep ${BASEDIR}/var/run)" ]; then
        umount ${BASEDIR}/var/run
    fi
fi
rm ${BASEDIR}/etc/resolv.conf
