#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: flash.sh,v 1.3 2006/10/01 11:54:07 drizzt Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

echo "#### Flashing bootable UFS image for ${ARCH} ####"

GHOSTBSD_LABEL=${GHOSTBSD_LABEL:-"GhostBSD"}

DEF_DEV=/dev/da0

echo -n "Device where your CF card is attached [${DEF_DEV}]: "
read DEVICE

if [ -z "${DEVICE}" ]; then
    DEVICE=$DEF_DEV
fi

if [ ! -c "${DEVICE}" ]; then
    echo "Unable to find ${DEVICE}, please check the pathname"
    exit 1;
fi

# Temporary mount point
TMPDIR=`mktemp -d -t ghostbsd`

echo "Initializing ${DEVICE}..."

fdisk -BI ${DEVICE} >> ${LOGFILE} 2>&1

bsdlabel -w -B ${DEVICE}s1 >> ${LOGFILE} 2>&1

newfs -b 4096 -f 512 -i 8192 -L ${GHOSTBSD_LABEL} -O1 -U ${DEVICE}s1a >> ${LOGFILE} 2>&1
mount ${DEVICE}s1a ${TMPDIR}

echo "Writing files..."

cd ${CLONEDIR}
find . -print -depth | cpio -dump -v ${TMPDIR} >> ${LOGFILE} 2>&1
echo "/dev/ufs/${GHOSTBSD_LABEL} / ufs ro 1 1" > ${TMPDIR}/etc/fstab
echo "proc /proc procfs rw 0 0" >> ${TMPDIR}/etc/fstab
echo "linproc /usr/compat/linux/proc linprocfs rw 0 0" >> ${TMPDIR}/etc/fstab

umount ${TMPDIR}
cd ${LOCALDIR}

rm -rf ${TMPDIR}
