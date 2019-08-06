#!/bin/sh

set -e -u

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
permit nopass keepenv :wheel cmd rc-service
permit nopass keepenv :wheel cmd wpa_supplicant
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
