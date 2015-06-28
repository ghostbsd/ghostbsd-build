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

jail_name=${PACK_PROFILE}${ARCH}

mkmd_device()
{
UFSFILE=${BASEDIR}/dist/uzip/usrimg
MOUNTPOINT=${BASEDIR}/usr
FSSIZE=$(echo "${USR_SIZE}*1024^2" | bc | cut -d . -f1)

for dirs in union uzip cdmnt ; do
    if [ ! -d ${BASEDIR}/dist/${dirs} ]; then
        mkdir -p ${BASEDIR}/dist/${dirs}
    fi
done

for dir in  ${UNION_DIRS}; do
  echo ${dir} >> ${BASEDIR}/dist/uniondirs
done

if [ ! -d ${BASEDIR}/compat/linux/proc ]; then
    mkdir -p ${BASEDIR}/compat/linux/proc
fi

if [ "${MD_BACKEND}" = "file" ] 
    then
        dd if=/dev/zero of=${UFSFILE} bs=1k count=1 seek=$((${FSSIZE} - 1))
        DEVICE=$(mdconfig -a -t vnode -f ${UFSFILE})
    else
        DEVICE=$(mdconfig -a -t malloc -s ${FSSIZE}k)
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
        cd $BASEDIR
        tar -yxf ${files}.txz -C ./
        rm -f ${files}.txz
    done
else 
    for files in ${I386_COMPONENTS} ; do
        cd $BASEDIR
        tar -yxf ${files}.txz -C ./
        rm -f ${files}.txz
    done
fi
}

jail_add()
{
cat >> /etc/jail.conf << EOF
${PACK_PROFILE}${ARCH} {
path = ${BASEDIR};
mount.devfs;
host.hostname = www.${PACK_PROFILE}${ARCH}.org;
ip4.addr=${NEXT_IP};
interface=${NETIF};
exec.start = "/bin/sh /etc/rc";
exec.stop = "/bin/sh /etc/rc.shutdown";
}
EOF
}

jail_list_add()
{
get_jail=$(grep $jail_name /etc/jail.conf| grep -v host.hostname |cut -d \  -f1 )
isalready=false

if [ -n $get_jail ] ; then
    for ijail in $get_jail; do
        if [ "$ijail" = "$jail_name" ]; then 
            isalready=true
        fi
    done
fi

if [ "$isalready" = "false" -o -z $get_jail ]  ;then
   jail_add
else
    echo "jail already exists and won't be added"
    break
fi
}

netconfig()
{
last_seq=$(ifconfig | grep "status: active" -IB3| head -n1 | awk '{print $2}' | cut -d . -f4)
flast_seq=$(ifconfig | grep "status: active" -IB3| head -n1 | awk '{print $2}' | cut -d . -f1,2,3)
START_IP=${flast_seq}.$(expr $last_seq + $INCREMENT )
# NETIF should be your's already configured network card
NETIF=$(ifconfig | grep "status: active" -IB6| head -n1 | cut -d : -f1)
}

inc_ip()
{
touch /etc/jail.conf
LAST_IP=$(grep ip4.addr /etc/jail.conf | tail -n 1 | cut -d = -f2 | cut -d \; -f1)
LAST_SEQ=$(grep ip4.addr /etc/jail.conf | tail -n 1 | cut -d = -f2 | cut -d \; -f1 | cut -d . -f4)
if [ -z $LAST_IP ]; then
   NEXT_IP=$START_IP
else
IP=`expr $LAST_SEQ + 1 `
FLAST_SEQ=$(grep ip4.addr /etc/jail.conf | tail -n 1 | cut -d = -f2 | cut -d \; -f1 | cut -d . -f1,2,3)
NEXT_IP=$FLAST_SEQ.$IP
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
fi

if ${USE_JAILS}; then
    netconfig
    inc_ip
    jail_list_add
    service jail onestart $jail_name
fi

set -e
cd $LOCALDIR
