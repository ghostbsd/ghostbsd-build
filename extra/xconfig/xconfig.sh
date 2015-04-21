#!/bin/sh
#
# Copyright (c) 2002-2004 G.U.F.I.
# Copyright (c) 2005-2006 Matteo Riondato & Dario Freni
#
# See COPYING for licence terms.
#
# $Id: xconfig.sh,v 1.3 2007/01/16 08:14:12 rionda Exp $
#
# Video Card Detection script
#
#
# PROVIDE: xconfig
# REQUIRE: etcmfs

. /etc/rc.subr

name="xconfig"
start_cmd="create_xorgconf"
stop_cmd=":"

create_xorgconf() {

if [ ! -f /usr/local/bin/X ]; then
    exit
fi

echo -n "Creating xorg.conf..."

PATH_DEST=/etc/X11
X_CFG_ORIG=${PATH_DEST}/xorg.conf.orig
X_CFG_VBOX=${PATH_DEST}/xorg.conf.vbox
X_CFG=${PATH_DEST}/xorg.conf

if [ -f ${X_CFG} ]; then
    echo "xorg.conf found... skipping"
    exit
fi

pciconf="/usr/sbin/pciconf -lv"

pciline=$(${pciconf} | grep -B 4 VGA)

vendor=$(echo ${pciline} | grep vendor)
device=$(echo ${pciline} | grep device)


echo -n " using \"${DRIVER_STR}\" driver..."

case "${DRIVER_STR:-NULL}" in
NULL)
	echo "no drivers found... using vesa"
	cp ${X_CFG_ORIG} ${X_CFG}
	;;
vesa)
	cp ${X_CFG_ORIG} ${X_CFG}
	;;
vbox)
    cp ${X_CFG_VBOX} ${X_CFG}
*)
	sed "s/vesa/${DRIVER_STR}/" < ${X_CFG_ORIG} > ${X_CFG}
	;;
esac

echo " done."

}

load_rc_config $name
run_rc_command "$1"

