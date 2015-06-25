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
git clone https://github.com/angelescuo/ports.git ${BASEDIR}/ports >/dev/null 2>&1

# checks for build restart
if [ -d ${BASEDIR}/ghostbsd/All ]; then
    rm -Rf ${BASEDIR}/ghostbsd
fi
mkdir -p ${BASEDIR}/ghostbsd/All

if [ ! -d ${BASEDIR}/usr/local/etc/pkg/repos ]; then
    mkdir -p ${BASEDIR}/usr/local/etc/pkg/repos
fi

# create ghostbsd local repo config file
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

# build ghostbsd ports 
cp -af ${PKGFILE} ${BASEDIR}/mnt

cat > ${BASEDIR}/mnt/portsbuild.sh << "EOF"
#!/bin/sh 

pkgfile="ghostbsd"

cd /mnt

while read pkgc; do
    if [ -n "${pkgc}" ] ; then
        echo "Buildinging port $pkgc"
        # builds ghostbsd ports in chroot
        for port in $(find /ports/ -type d -depth 2 -name ${pkgc})  ; do
        echo $port
        cd $port
        make
        make package
        cd work/pkg
        mv *txz /ghostbsd/All
        done

    #populates ghostbsd repo in chroot
    pkg repo /ghostbsd
    fi
done < $pkgfile

rm -f /mnt/portsbuild.sh
EOF


# Build ghostbsd ports in chroot 
chrootcmd="chroot ${BASEDIR} sh /mnt/portsbuild.sh"
$chrootcmd

rm -Rf ${BASEDIR}/ports

# Install built ghostbsd ports
PLOGFILE=".log_portsinstall"

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
EOF

chrootcmd="chroot ${BASEDIR} sh /mnt/portsadded.sh"

$chrootcmd

# removes ghostbsd local repo
rm -Rf ${BASEDIR}/ghostbsd 
rm -f ${BASEDIR}/usr/local/etc/pkg/repos/GhostBSD.conf

# save logfile where should be
mv ${BASEDIR}/mnt/${PLOGFILE} ${MAKEOBJDIRPREFIX}/${LOCALDIR}

# umount /var/run if not using jails
if ! ${USE_JAILS} ; then
    if [ -n "$(mount | grep ${BASEDIR}/var/run)" ]; then
        umount ${BASEDIR}/var/run
    fi
fi
rm ${BASEDIR}/etc/resolv.conf
