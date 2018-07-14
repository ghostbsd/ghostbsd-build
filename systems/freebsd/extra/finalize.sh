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

clean_desktop_files()
{
# Remove Gnome and Mate from ShowOnly in *.desktop
# needed for update-station
  DesktopBSD=`ls ${BASEDIR}/usr/local/share/applications/ | grep -v libreoffice | grep -v kde4 | grep -v screensavers`
  for desktop in $DesktopBSD; do
    sed -i "" -e 's/OnlyShowIn=Gnome;//g' ${BASEDIR}/usr/local/share/applications/$desktop
    sed -i "" -e 's/OnlyShowIn=MATE;//g' ${BASEDIR}/usr/local/share/applications/$desktop
    sed -i "" -e 's/GNOME;//g' ${BASEDIR}/usr/local/share/applications/$desktop
    sed -i "" -e 's/MATE;//g' ${BASEDIR}/usr/local/share/applications/$desktop
    sed -i "" -e 's/OnlyShowIn=//g' ${BASEDIR}/usr/local/share/applications/$desktop
  done
}

default_ghostbsd_rc_conf()
{
  rm ${BASEDIR}/etc/rc.d/virtualbox
  cp  ${BASEDIR}/etc/rc.conf ${BASEDIR}/etc/rc.conf.ghostbsd
}

set_sudoers()
{
  sed -i "" -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' ${BASEDIR}/usr/local/etc/sudoers
  sed -i "" -e 's/# %sudo/%sudo/g' ${BASEDIR}/usr/local/etc/sudoers
}

dot_xinitrc()
{
#echo 'exec $1' > ${BASEDIR}/home/ghostbsd/.xinitrc
#echo 'exec $1' > ${BASEDIR}/root/.xinitrc

if [ "${PACK_PROFILE}" == "mate" ] ; then
  echo "exec ck-launch-session mate-session" > ${BASEDIR}/usr/home/ghostbsd/.xinitrc
  echo "exec ck-launch-session mate-session" > ${BASEDIR}/root/.xinitrc
elif [ "${PACK_PROFILE}" == "xfce" ] ; then
  echo "exec ck-launch-session startxfce4" > ${BASEDIR}/usr/home/ghostbsd/.xinitrc
  echo "exec ck-launch-session startxfce4" > ${BASEDIR}/root/.xinitrc
fi
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
" > ${BASEDIR}/usr/local/etc/doas.conf
}

reinstall_LigthDM()
{

cat > ${BASEDIR}/mnt/addpkg.sh << "EOF"
#!/bin/sh

FORCE_PKG_REGISTER=true
export FORCE_PKG_REGISTER

# pkg bootstrap with env
env ASSUME_ALWAYS_YES=YES pkg bootstrap

# pkg install part
pkgfile="${PACK_PROFILE}-packages"
pkgaddcmd="pkg install -yf "

$pkgaddcmd lightdm
echo "lightdm installed"
EOF

# run addpkg.sh in chroot to add packages
chrootcmd="chroot ${BASEDIR} sh /mnt/addpkg.sh"
$chrootcmd
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
EndSection' > ${BASEDIR}/usr/local/etc/X11/xorg.conf.d/vmware.conf

printf 'vmware_guest_vmblock_enable="YES"
vmware_guest_vmhgfs_enable="YES"
vmware_guest_vmmemctl_enable="YES"
vmware_guest_vmxnet_enable="YES"
vmware_guestd_enable="YES"' > ${BASEDIR}/etc/rc.conf.d/vmware.conf
}

enable_sddm()
{
  chrootcmd="chroot ${BASEDIR} /sbin/rc-update add sddm default"
  $chrootcmd
}

clean_desktop_files
default_ghostbsd_rc_conf
set_sudoers
set_doas
dot_xinitrc
# reinstall_LigthDM
enable_sddm
