#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# finalize.sh,v 1.0 Wed 17 Jun 19:42:49 ADT 2015cd  Ovidiu Angelescu
#

set -e -u

if [ -z "${LOGFILE:-}" ] ; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

default_ghostbsd_rc_conf()
{
  cp  ${release}/etc/rc.conf ${release}/etc/rc.conf.ghostbsd
}

set_sudoers()
{
  sed -i "" -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' ${release}/usr/local/etc/sudoers
  sed -i "" -e 's/# %sudo/%sudo/g' ${release}/usr/local/etc/sudoers
}

set_doas()
{
  printf "permit nopass keepenv root
permit :wheel
permit nopass keepenv :wheel cmd netcardmgr
permit nopass keepenv :wheel cmd ifconfig
permit nopass keepenv :wheel cmd service
permit nopass keepenv :wheel cmd wpa_supplicant
permit nopass keepenv :wheel cmd fbsdupdatecheck
permit nopass keepenv :wheel cmd fbsdpkgupdate
permit nopass keepenv :wheel cmd pkg args upgrade -y
permit nopass keepenv :wheel cmd pkg args upgrade -Fy
permit nopass keepenv :wheel cmd pkg args lock
permit nopass keepenv :wheel cmd pkg args unlock
permit nopass keepenv :wheel cmd mkdir args -p /var/db/update-station/
permit nopass keepenv :wheel cmd chmod args -R 665 /var/db/update-station/
permit nopass keepenv :wheel cmd sh args /usr/local/lib/update-station/cleandesktop.sh
permit nopass keepenv :wheel cmd shutdown args -r now
" > ${release}/usr/local/etc/doas.conf
}

vmware_supports()
{
printf 'Section "ServerFlags"
Option "AutoAddDevices" "false"
EndSection
Section "InputDevice"
Identifier "Mouse0"
Driver "vmmouse"
Option "Device" "/dev/sysmouse"
EndSection' > ${release}/usr/local/etc/X11/xorg.conf.d/vmware.conf

printf 'vmware_guest_vmblock_enable="YES"
vmware_guest_vmhgfs_enable="YES"
vmware_guest_vmmemctl_enable="YES"
vmware_guest_vmxnet_enable="YES"
vmware_guestd_enable="YES"' > ${release}/etc/rc.conf.d/vmware.conf
}

final_setup()
{
  default_ghostbsd_rc_conf
  set_sudoers
  set_doas
  vmware_supports
}
