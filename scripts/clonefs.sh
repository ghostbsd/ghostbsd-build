#!/bin/sh
#
# Copyright (c) 2009-2014, GhostBSD Project All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistribution's of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistribution's in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Id: clonefs.sh,v 1.13 Saturday, June 20 2015 Ovidiu Angelescu $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi


# Cloning file system function. 
clonefs()
{
# Copying file system without /usr and /var/cache/pkg
echo "### Preparing filesystem hierarchy using $MD_BACKEND backend."
mkdir -p ${CLONEDIR}
rsync -avzH --exclude-from='conf/clonefs_exclusion' ${BASEDIR}/ ${CLONEDIR} >> ${LOGFILE} 2>&1

# Making the directory for linprocfs.
if [ ! -d ${CLONEDIR}/compat/linux/proc ]; then
  mkdir -p ${CLONEDIR}/compat/linux/proc
fi

# Copying /usr in the clonedir. 
rsync -avzH --exclude '.svn' ${BASEDIR}/usr/ ${CLONEDIR}/usr >> ${LOGFILE} 2>&1
}

uniondirs_prepare()
{
echo "### Preparing union dirs"
echo "### Preparing union dirs" >> ${LOGFILE} 2>&1
echo ${UNION_DIRS} >> ${LOGFILE} 2>&1


for dirs in union uzip ; do
    if [ ! -d ${CLONEDIR}/dist/${dirs} ]; then
        mkdir -p ${CLONEDIR}/dist/${dirs}
    fi
done

if [ ! -d "${CLONEDIR}/cdmnt-install" ] ; then
  mkdir -p ${CLONEDIR}/cdmnt-install
fi

if [ -f "${CLONEDIR}/dist/uniondirs" ] ; then
  rm ${CLONEDIR}/dist/uniondirs
fi

for dir in  ${UNION_DIRS}; do
  echo ${dir} >> ${CLONEDIR}/dist/uniondirs
done

if [ -f ${CLONEDIR}/etc/rc.d/uzip ] ; then
  chmod 555 ${CLONEDIR}/etc/rc.d/uzip
fi

if [ -f ${CLONEDIR}/etc/rc.d/unionfs ] ; then
  chmod 555 ${CLONEDIR}/etc/rc.d/unionfs
fi

}

compress_fs()
{
echo "### Compressing filesystem using ${MD_BACKEND} backend."
if [ "${MD_BACKEND}" = "file" ] ; then
  mkuzip -v -o ${CLONEDIR}/dist/uzip/usr.uzip -s 65536 ${CLONEDIR}/dist/uzip/usrimg >> ${LOGFILE} 2>&1
  rm -f ${CLONEDIR}/dist/uzip/usrimg
else
  mkuzip -v -o ${CLONEDIR}/dist/uzip/usr.uzip  -s 65536 /dev/${DEVICE} >> ${LOGFILE} 2>&1
fi
}

mount_ufs()
{
echo "### Making and mounting device for compressing filesystem using $MD_BACKEND"
echo "### Making and mounting device for compressing filesystem using $MD_BACKEND" >> ${LOGFILE} 2>&1


UFSFILE=${CLONEDIR}/dist/uzip/usrimg
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
