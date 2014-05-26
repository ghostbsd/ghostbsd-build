#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: clonefs.sh,v 1.12 2007/01/16 08:30:08 rionda Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi


# Cloning file system function. 
clonefs()
{
# Copying file system without /usr.
echo "### Preparing filesystem hierarchy using $MD_BACKEND backend."
mkdir -p ${CLONEDIR}
rsync -avzH --exclude-from='conf/clonefs_exclusion' ${BASEDIR}/ ${CLONEDIR} >> ${LOGFILE} 2>&1

# Making the directory for linprocfs and uzip.
if [ ! -d ${CLONEDIR}/compat/linux/proc ];
then
  mkdir -p ${CLONEDIR}/compat/linux/proc
fi
if [ ! -d ${CLONEDIR}/uzip ] ; then
  mkdir -p ${CLONEDIR}/uzip
fi

# Copying /usr in the clonedir. 
rsync -avzH --exclude '.svn' ${BASEDIR}/usr/ ${CLONEDIR}/usr >> ${LOGFILE} 2>&1
}

uniondirs_prepare()
{
echo "### Preparing union dirs"
echo "### Preparing union dirs" >> ${LOGFILE} 2>&1
echo ${UNION_DIRS} >> ${LOGFILE} 2>&1

mkdir -p ${CLONEDIR}/dist ${CLONEDIR}/dist/union ${CLONEDIR}/dist/union/usr ${CLONEDIR}/cdmnt-install

if [ -f "${CLONEDIR}/dist/uniondirs" ] ; then
  rm ${CLONEDIR}/dist/uniondirs
fi

for dir in  ${UNION_DIRS}; do
  echo ${dir} >> ${CLONEDIR}/dist/uniondirs
  cd ${CLONEDIR} && tar -cpzf ${CLONEDIR}/dist/mfs.tgz ./${UNION_DIRS}
done

if [ ! -f ${CLONEDIR}/etc/rc.d/uzip ] ; then
  cp ${LOCALDIR}/conf/rc.d/uzip ${CLONEDIR}/etc/rc.d/
  chmod 555 ${CLONEDIR}/etc/rc.d/uzip
fi

if [ ! -f ${CLONEDIR}/etc/rc.d/unionfs ] ; then
  cp ${LOCALDIR}/conf/rc.d/unionfs ${CLONEDIR}/etc/rc.d/
  chmod 555 ${CLONEDIR}/etc/rc.d/unionfs
fi

# Removes duplicates from usr after archived them
for i in /usr/local/etc /usr/local/www ; do
rm -Rf ${CLONEDIR}/$i/*
done
}

compress_fs()
{
echo "### Compressing filesystem using ${MD_BACKEND} backend."
if [ "${MD_BACKEND}" = "file" ] ; then
  mkuzip -v -o ${CLONEDIR}/uzip/usr.uzip -s 65536 ${CLONEDIR}/uzip/usrimg >> ${LOGFILE} 2>&1
  rm -f ${CLONEDIR}/uzip/usrimg
else
  mkuzip -v -o ${CLONEDIR}/uzip/usr.uzip  -s 65536 /dev/${DEVICE} >> ${LOGFILE} 2>&1
fi
}

mount_ufs()
{
echo "### Making and mounting device for compressing filesystem using $MD_BACKEND"
echo "### Making and mounting device for compressing filesystem using $MD_BACKEND" >> ${LOGFILE} 2>&1
mkdir -p ${CLONEDIR}/uzip
UFSFILE=${CLONEDIR}/uzip/usrimg
MOUNTPOINT=${CLONEDIR}/usr
DIRSIZE=$(($(du -kd 0 -I ".svn" ${BASEDIR}/usr | cut -f 1)))
FSSIZE=$(($DIRSIZE + ($DIRSIZE/5)))

if [ "${MD_BACKEND}" = "file" ] 
    then
        dd if=/dev/zero of=${UFSFILE} bs=1k count=1 seek=$((${FSSIZE} - 1))
        DEVICE=$(mdconfig -a -t vnode -f ${UFSFILE})
    else
        DEVICE=$(mdconfig -a -t malloc -s ${FSSIZE}k)
        dd if=/dev/zero of=/dev/${DEVICE} bs=1k count=1 seek=$((${FSSIZE} - 1))
fi

newfs -o space /dev/${DEVICE} 
mkdir -p ${MOUNTPOINT}
mount -o noatime /dev/${DEVICE} ${MOUNTPOINT}

clonefs

uniondirs_prepare

umount -f ${MOUNTPOINT}

DEVICE_NO=`echo ${DEVICE} | cut -d 'd' -f2`

if [ "${MD_BACKEND}" = "file" ] 
    then
        mdconfig -d -u ${DEVICE_NO}
        compress_fs
    else
        compress_fs
        mdconfig -d -u ${DEVICE_NO}
fi
echo "### Done filesystem compress"
echo "### Done filesystem compress" >> ${LOGFILE} 2>&1
}

mount_ufs
