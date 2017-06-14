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

DEVICE=`cat ${BASEDIR}/mddevice`

make_manifest()
{
echo "### Make iso manifest."
echo "### Make iso manifest." >> ${LOGFILE} 2>&1
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

uniondirs_prepare()
{
echo "### Prepare for compression build environment"
echo "### Prepare for compression build environment" >> ${LOGFILE} 2>&1
for files in unionfs uzip ; do
    if [ -f ${BASEDIR}/etc/rc.d/$files ] ; then
        chmod 555 ${BASEDIR}/etc/rc.d/$files
    fi
done
# clean packages cache, tmp and var/log
rm -f  ${BASEDIR}/var/cache/pkg/*
rm -Rf ${BASEDIR}/tmp/*
rm -Rf ${BASEDIR}/var/log/*
# makes usr/src/sys dir because of cosmetical reason
mkdir -p ${BASEDIR}/usr/src/sys
}

compress_fs()
{
echo "### Compressing filesystem using $MD_BACKEND"
echo "### Compressing filesystem using $MD_BACKEND" >> ${LOGFILE} 2>&1
if [ "${MD_BACKEND}" = "file" ] ; then
  mkuzip -v -o ${BASEDIR}/dist/uzip/usr.uzip -s 65536 ${BASEDIR}/dist/uzip/usrimg >> ${LOGFILE} 2>&1
  rm -f ${BASEDIR}/dist/uzip/usrimg
else
  mkuzip -v -o ${BASEDIR}/dist/uzip/usr.uzip  -s 65536 /dev/${DEVICE} >> ${LOGFILE} 2>&1
fi
}

mount_ufs()
{
DIRSIZE=$(($(du -kd 0 ${BASEDIR}/usr | cut -f 1)))
echo "${PACK_PROFILE}${ARCH}_${BDATE}_mdsize=$(($DIRSIZE + ($DIRSIZE/10)))" > ${BASEDIR}/dist/mdsize

MOUNTPOINT=${BASEDIR}/usr
umount -f ${MOUNTPOINT}
uniondirs_prepare

if [ "${MD_BACKEND}" = "file" ]
    then
        mdconfig -d -u ${DEVICE}
        compress_fs
    else
        compress_fs
        mdconfig -d -u ${DEVICE}
fi
rm -f ${BASEDIR}/mddevice
echo "### Done filesystem compress"
echo "### Done filesystem compress" >> ${LOGFILE} 2>&1
}

make_manifest
mount_ufs

set -e
cd ${LOCALDIR}
