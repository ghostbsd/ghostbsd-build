#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# $GhostBSD$
# $Id: iso.sh,v 1.7 Thu Dec 15 18:08:31 AST 2011 Eric

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

GHOSTBSD_LABEL=${GHOSTBSD_LABEL:-"GhostBSD"}

echo "#### Building bootable ISO image for ${ARCH} ####"

echo "Saving mtree structure..."
mtree -Pcp ${BASEDIR}/usr/home  > ${CLONEDIR}/dist/home.dist

# Creates etc/fstab to avoid messages about missing it
if [ ! -e ${CLONEDIR}/etc/fstab ] ; then
    touch ${CLONEDIR}/etc/fstab
fi

cd ${CLONEDIR} && tar -cpzf ${CLONEDIR}/dist/etc.tgz etc

#echo "### Running makefs to create ISO ###"
#bootable="-o bootimage=i386;${CLONEDIR}/boot/cdboot -o no-emul-boot"
#makefs -t cd9660 $bootable -o rockridge -o label=${GHOSTBSD_LABEL} ${ISOPATH} ${CLONEDIR}

# Reference for hybrid DVD/USB image
# Use GRUB to create the hybrid DVD/USB image
echo "Creating ISO..."
grub-mkrescue -o ${ISOPATH} ${CLONEDIR} -- -volid ${GHOSTBSD_LABEL}
if [ $? -ne 0 ] ; then
	echo "Failed running grub-mkrescue"
	exit 1
fi

make_manifest()
{
cat > ${BASEDIR}/mnt/manifest.sh << "EOF"
#!/bin/sh 
# builds iso manifest
cd /mnt
pkg info > manifest
rm manifest.sh
EOF


chrootcmd="chroot ${BASEDIR} sh /mnt/manifest.sh"
$chrootcmd

if [ ! -d /usr/obj/${ARCH}/${PACK_PROFILE} ]; then
    mkdir -p /usr/obj/${ARCH}/${PACK_PROFILE}
fi
mv -f ${BASEDIR}/mnt/manifest /usr/obj/${ARCH}/${PACK_PROFILE}/$(echo ${ISOPATH} | cut -d / -f6).manifest
}

echo "### ISO created ###"

# Make md5 and sha256 for iso
make_checksums()
{
cd /usr/obj/${ARCH}/${PACK_PROFILE}
md5 `echo ${ISOPATH}|cut -d / -f6`  >> /usr/obj/${ARCH}/${PACK_PROFILE}/$(echo ${ISOPATH}|cut -d / -f6).md5
sha256 `echo ${ISOPATH}| cut -d / -f6` >> /usr/obj/${ARCH}/${PACK_PROFILE}/$(echo ${ISOPATH}|cut -d / -f6).sha256
cd -
}

make_manifest
make_checksums

cd ${LOCALDIR}
