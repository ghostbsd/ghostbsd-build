#!/usr/bin/env sh

set -e -u

export cwd="`realpath | sed 's|/scripts||g'`"
# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

kernrel="`uname -r`"

case $kernrel in
  '13.0-ALPHA3'|'13.0-BETA1'|'13.0-BETA2'|'13.0-BETA3'|'13.0-RC1'|'13.0-RC2'|'13.0-RC3'|'13.0-STABLE') ;;
  *)
    echo "Using wrong kernel release. Use GhostBSD 20.04 or later to build iso."
    exit 1
    ;;
esac

desktop_list=`ls ${cwd}/packages | tr '\n' ' '`

helpFunction()
{
   echo "Usage: $0 -d desktop -r release type"
   echo -e "\t-h for help"
   echo -e "\t-d Desktop: ${desktop_list}"
   echo -e "\t-r Release: devel or release"
   exit 1 # Exit script after printing help
}

# Set mate and release to be default
export desktop="mate"
export release_type="release"

while getopts "d:r:" opt
do
   case "$opt" in
      'd') export desktop="$OPTARG" ;;
      'r') export release_type="$OPTARG" ;;
      'h') helpFunction ;;
      '?') helpFunction ;;
      *) helpFunction ;;
   esac
done


validate_desktop()
{
  if [ ! -f "${cwd}/packages/${desktop}" ] ; then
    echo "Invalid choice specified"
    echo "Possible choices are:"
    echo $desktop_list
    echo "Usage: ./build.sh mate"
    exit 1
  fi
}

validate_desktop

if [ "${desktop}" != "mate" ] ; then
  DESKTOP=$(echo ${desktop} | tr [a-z] [A-Z])
  community="-${DESKTOP}"
else
  community=""
fi

workdir="/usr/local"
livecd="${workdir}/ghostbsd-build"
base="${livecd}/base"
iso="${livecd}/iso"
software_packages="${livecd}/software_packages"
base_packages="${livecd}/base_packages"
release="${livecd}/release"
cdroot="${livecd}/cdroot"
liveuser="ghostbsd"

version=`date "+-%y.%m.%d"`
time_stamp=""
release_stamp=""
label="GhostBSD"
isopath="${iso}/${label}${version}${release_stamp}${time_stamp}${community}.iso"

workspace()
{
  umount ${release}/dev >/dev/null 2>/dev/null || true
  umount ${base_packages} >/dev/null 2>/dev/null || true
  umount ${release} >/dev/null 2>/dev/null || true
  if [ -d "${cdroot}" ] ; then
    chflags -R noschg ${cdroot}
    rm -rf ${cdroot}
  fi
  zpool destroy ghostbsd >/dev/null 2>/dev/null || true
  umount ghostbsd >/dev/null 2>/dev/null || true
  mdconfig -d -u 0 >/dev/null 2>/dev/null || true
  if [ -f "${livecd}/pool.img" ] ; then
    rm ${livecd}/pool.img
  fi
  mkdir -p ${livecd} ${base} ${iso} ${software_packages} ${base_packages} ${release}
  truncate -s 6g ${livecd}/pool.img
  mdconfig -f ${livecd}/pool.img -u 0
  zpool create ghostbsd /dev/md0
  zfs set mountpoint=${release} ghostbsd
  zfs set compression=gzip-6 ghostbsd
}

base()
{
  mkdir -p ${release}/etc
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${base_packages} ${release}/var/cache/pkg
  pkg-static -r ${release} -R ${cwd}/pkg/ -C GhostBSD_PKG install -y -g os-generic-kernel os-generic-userland os-generic-userland-lib32 os-generic-userland-devtools

  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  touch ${release}/etc/fstab
  mkdir ${release}/cdrom
}

packages_software()
{
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${software_packages} ${release}/var/cache/pkg
  mount -t devfs devfs ${release}/dev
  cat ${cwd}/packages/${desktop} | xargs pkg -c ${release} install -y
  mkdir -p ${release}/compat/linux/proc
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
}

rc()
{
  chroot ${release} touch /etc/rc.conf
  chroot ${release} sysrc hostname='livecd'
  chroot ${release} sysrc kld_list="linux linux64 cuse fusefs"
  chroot ${release} sysrc linux_enable="YES"
  chroot ${release} sysrc devfs_enable="YES"
  chroot ${release} sysrc devfs_system_ruleset="devfsrules_common"
  chroot ${release} rc-update add moused default
  chroot ${release} sysrc moused_enable="YES"
  chroot ${release} rc-update add dbus default
  chroot ${release} sysrc dbus_enable="YES"
  chroot ${release} rc-update add webcamd default
  chroot ${release} sysrc webcamd_enable="YES"
  chroot ${release} rc-update add ipfw default
  chroot ${release} sysrc ipfw_enable="YES"
  chroot ${release} rc-update add cupsd default
  chroot ${release} sysrc cupsd_enable="YES"
  chroot ${release} rc-update add avahi-daemon default
  chroot ${release} sysrc avahi-daemon_enable="YES"
  chroot ${release} rc-update add avahi-dnsconfd default
  chroot ${release} sysrc avahi-dnsconfd_enable="YES"
  chroot ${release} rc-update --update
  chroot ${release} sysrc ntpd_enable="YES"
  chroot ${release} sysrc ntpd_sync_on_start="YES"
}

user()
{
  chroot ${release} pw useradd ${liveuser} \
  -c "GhostBSD Live User" -d "/usr/home/${liveuser}"\
  -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
  chroot ${release} su ${liveuser} -c "mkdir -p /usr/home/${liveuser}/Desktop"
  if [ -e ${release}/usr/local/share/applications/gbi.desktop ] ; then
    chroot ${release} su ${liveuser} -c  "cp -af /usr/local/share/applications/gbi.desktop /usr/home/${liveuser}/Desktop"
    chroot ${release} su ${liveuser} -c  "chmod +x /usr/home/${liveuser}/Desktop/gbi.desktop"
    sed -i '' -e 's/NoDisplay=true/NoDisplay=false/g' ${release}/usr/home/${liveuser}/Desktop/gbi.desktop
  fi
}

extra_config()
{
  . ${cwd}/extra/common-live-setting.sh
  . ${cwd}/extra/common-base-setting.sh
  . ${cwd}/extra/dm.sh
  . ${cwd}/extra/finalize.sh
  . ${cwd}/extra/autologin.sh
  . ${cwd}/extra/gitpkg.sh
  set_live_system
  # git_pc_sysinstall
  ## git_gbi is for development testing and gbi should be
  ## remove from the package list to avoid conflict
  # git_gbi
  setup_base
  lightdm_setup
  setup_autologin
  final_setup
  echo "gop set 0" >> ${release}/boot/loader.rc.local
  # To fix lightdm crashing to be remove on the new base update.
  sed -i '' -e 's/memorylocked=128M/memorylocked=256M/g' ${release}/etc/login.conf
  chroot ${release} cap_mkdb /etc/login.conf
  mkdir -p ${release}/usr/local/share/ghostbsd
  echo "${desktop}" > ${release}/usr/local/share/ghostbsd/desktop
  echo "${liveuser}" > ${release}/usr/local/share/ghostbsd/liveuser
  # bypass automount for live
  mv ${release}/usr/local/etc/devd-openrc/automount_devd.conf ${release}/usr/local/etc/devd-openrc/automount_devd.conf.skip
  # Mkdir for linux compat to ensure /etc/fstab can mount when booting LiveCD
  chroot ${release} mkdir -p /compat/linux/dev/shm
  # Add /boot/entropy file
  chroot ${release} touch /boot/entropy
}

xorg()
{
  if [ -n "${desktop}" ] ; then
    install -o root -g wheel -m 755 "${cwd}/xorg/bin/xconfig" "${release}/usr/local/bin/"
    # install -o root -g wheel -m 755 "${cwd}/xorg/rc.d/xconfig" "${release}/usr/local/etc/rc.d/"
    # if [ -f "${release}/sbin/openrc-run" ] ; then
    #   install -o root -g wheel -m 755 "${cwd}/xorg/init.d/xconfig" "${release}/usr/local/etc/init.d/"
    # fi
    if [ ! -d "${release}/usr/local/etc/X11/cardDetect/" ] ; then
      mkdir -p ${release}/usr/local/etc/X11/cardDetect
    fi
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.vesa" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.scfb" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.virtualbox" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.vmware" "${release}/usr/local/etc/X11/cardDetect/"
  fi
}

uzip()
{
  umount ${release}/dev
  install -o root -g wheel -m 755 -d "${cdroot}"
  mkdir "${cdroot}/data"
  zfs snapshot ghostbsd@clean
  zfs send -c -e ghostbsd@clean | dd of=/usr/local/ghostbsd-build/cdroot/data/system.img status=progress bs=1M
}

ramdisk()
{
  ramdisk_root="${cdroot}/data/ramdisk"
  mkdir -p "${ramdisk_root}"
  cd "${release}"
  tar -cf - rescue | tar -xf - -C "${ramdisk_root}"
  cd "${cwd}"
  install -o root -g wheel -m 755 "init.sh.in" "${ramdisk_root}/init.sh"
  sed "s/@VOLUME@/GHOSTBSD/" "init.sh.in" > "${ramdisk_root}/init.sh"
  mkdir "${ramdisk_root}/dev"
  mkdir "${ramdisk_root}/etc"
  touch "${ramdisk_root}/etc/fstab"
  install -o root -g wheel -m 755 "rc.in" "${ramdisk_root}/etc/rc"
  cp ${release}/etc/login.conf ${ramdisk_root}/etc/login.conf
  makefs -b '10%' "${cdroot}/data/ramdisk.ufs" "${ramdisk_root}"
  gzip "${cdroot}/data/ramdisk.ufs"
  rm -rf "${ramdisk_root}"
}

boot()
{
  cd "${release}"
  tar -cf - boot | tar -xf - -C "${cdroot}"
  cp COPYRIGHT ${cdroot}/COPYRIGHT
  cd "${cwd}"
  cp LICENSE ${cdroot}/LICENSE
  cp -R boot/ ${cdroot}/boot/
  mkdir ${cdroot}/etc
  cd ${cwd} && zpool export ghostbsd && while zpool status ghostbsd >/dev/null; do :; done 2>/dev/null
}

image()
{
  sh mkisoimages.sh -b $label $isopath ${cdroot}
  ls -lh $isopath
  cd ${iso}
  shafile=$(echo ${isopath} | cut -d / -f6).sha256
  torrent=$(echo ${isopath} | cut -d / -f6).torrent
  tracker1="http://tracker.openbittorrent.com:80/announce"
  tracker2="udp://tracker.opentrackr.org:1337"
  tracker3="udp://tracker.coppersurfer.tk:6969"
  echo "Creating sha256 \"${iso}/${shafile}\""
  sha256 `echo ${isopath} | cut -d / -f6` > ${iso}/${shafile}
  transmission-create -o ${iso}/${torrent} -t ${tracker1} -t ${tracker3} -t ${tracker3} ${isopath}
  chmod 644 ${iso}/${torrent}
  cd -
}

workspace
base
packages_software
user
rc
extra_config
uzip
ramdisk
boot
image
