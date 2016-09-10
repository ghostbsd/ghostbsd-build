#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: installworld.sh,v 1.8 2006/06/11 18:29:50 saturnero Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

#jail_name=${PACK_PROFILE}${ARCH}
JAILFS=$(echo ${BASEDIR} | cut -d / -f 3,3)
jail_name=${JAILFS}${PACK_PROFILE}${ARCH}

mkmd_device()
{
UFSFILE=${BASEDIR}/dist/uzip/usrimg
MOUNTPOINT=${BASEDIR}/usr
FSSIZE=$(echo "${USR_SIZE}*1024^2" | bc | cut -d . -f1)

for dirs in union uzip ; do
    if [ ! -d ${BASEDIR}/dist/${dirs} ]; then
        mkdir -p ${BASEDIR}/dist/${dirs}
    fi
done

if [ ! -d ${BASEDIR}${CDMNT} ]; then
    mkdir -p ${BASEDIR}${CDMNT}
fi

for dir in  ${UNION_DIRS}; do
  echo ${dir} >> ${BASEDIR}/dist/uniondirs
done

if [ ! -d ${BASEDIR}/compat/linux/proc ]; then
    mkdir -p ${BASEDIR}/compat/linux/proc
fi

if [ "${MD_BACKEND}" = "file" ] 
    then
        FSSIZE=$(echo "${BACKEND_SIZE}*1024^2" | bc | cut -d . -f1)
        dd if=/dev/zero of=${UFSFILE} bs=1k count=1 seek=$((${FSSIZE} - 1))
        DEVICE=$(mdconfig -a -o async -t vnode -f ${UFSFILE})
    else
        FSSIZE=$(echo "${USR_SIZE}*1024^2" | bc | cut -d . -f1)
        DEVICE=$(mdconfig -a -o async -t malloc -s ${FSSIZE}k)
        dd if=/dev/zero of=/dev/${DEVICE} bs=1k count=1 seek=$((${FSSIZE} - 1))
fi

echo ${DEVICE} > ${BASEDIR}/mddevice

newfs -o space /dev/${DEVICE} 
mkdir -p ${MOUNTPOINT}
mount -o noatime /dev/${DEVICE} ${MOUNTPOINT}
}

install_built_world()
{
echo "#### Installing world for ${ARCH} architecture ####"

# Set MAKE_CONF variable if it's not already set.
if [ -z "${MAKE_CONF:-}" ]; then
    if [ -n "${MINIMAL:-}" ]; then
	MAKE_CONF=${LOCALDIR}/conf/make.conf.minimal
    else
	MAKE_CONF=${LOCALDIR}/conf/make.conf
    fi
fi

cd ${SRCDIR}

makeargs="${MAKEOPT:-} ${MAKEJ_WORLD:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} DESTDIR=${BASEDIR} SRCCONF=${SRC_CONF}"
(env $MAKE_ENV script -aq $LOGFILE make ${makeargs:-} installworld || print_error;) | grep '^>>>'

makeargs="${MAKEOPT:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} DESTDIR=${BASEDIR} SRCCONF=${SRC_CONF}"
set +e
(env $MAKE_ENV script -aq $LOGFILE make ${makeargs:-} distribution || print_error;) | grep '^>>>'
}

install_fetched_freebsd()
{
echo "#### Installing world for ${ARCH} architecture ####"
if [ "${ARCH}" = "amd64" ]; then
    for files in ${AMD64_COMPONENTS} ; do
        cd $CACHEDIR
        tar -yxf ${files}.txz -C $BASEDIR
        #rm -f ${files}.txz
    done
else 
    for files in ${I386_COMPONENTS} ; do
        cd $CACHEDIR
        tar -yxf ${files}.txz -C $BASEDIR
        #rm -f ${files}.txz
    done
fi
}

jail_add()
{
cat >> /etc/jail.conf << EOF
${jail_name}{
path = ${BASEDIR};
mount.devfs;
host.hostname = www.${jail_name}.org;
exec.start = "/bin/sh /etc/rc";
exec.stop = "/bin/sh /etc/rc.shutdown";
}
EOF
}

jail_list_add()
{
if [ ! -f /etc/jail.conf ] ; then
    touch /etc/jail.conf
fi

set +e 
grep ^"${jail_name}" /etc/jail.conf
if [ $? -ne  0 ] ; then
    jail_add
else
    echo "jail already exists and won't be added"
fi
}

# makes initial memory device to install over it
mkmd_device

if [ -n "${FETCH_FREEBSDBASE:-}" ]; then
    install_fetched_freebsd
else
    install_built_world
fi

if [ ! -d ${BASEDIR}/usr/local/etc/default ]; then
    mkdir -p ${BASEDIR}/usr/local/etc/default
    echo "${DISTRO}_FLAVOUR=${PACK_PROFILE}" > ${BASEDIR}/usr/local/etc/default/distro
    echo "${DISTRO}_VERSION=${VERSION}" >> ${BASEDIR}/usr/local/etc/default/distro
    echo "DISTRO_LIVEUSER=${GHOSTBSD_USER}" >> ${BASEDIR}/usr/local/etc/default/distro
fi

if ${USE_JAILS}; then
    jail_list_add
    service jail onestart $jail_name
fi

set -e
cd $LOCALDIR
