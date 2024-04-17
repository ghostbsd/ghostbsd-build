#!/usr/bin/env sh

set -e -u

cwd="$(realpath)"
export cwd

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

kernrel="$(uname -r)"

case $kernrel in
  '13.1-STABLE' | '13.2-STABLE' | '14.0-STABLE' | '15.0-CURRENT') ;;
  *)
    echo "Using wrong kernel release. Use GhostBSD 20.04 or later to build iso."
    exit 1
    ;;
esac

desktop_list=$(find packages -type f | cut -d '/' -f2 | tr -s '\n' ' ')
desktop_config_list=$(find desktop_config -type f)

help_function()
{
  printf "Usage: %s -d desktop -r release type" "$0"
  printf "\t-h for help"
  printf "\t-d Desktop: %s" "${desktop_list}"
  printf "\t-b Build type: unstable or release"
   exit 1 # Exit script after printing help
}

# Set mate and release to be default
export desktop="mate"
export build_type="release"

while getopts "d:b:h" opt
do
   case "$opt" in
      'd') export desktop="$OPTARG" ;;
      'b') export build_type="$OPTARG" ;;
      'h') help_function ;;
      '?') help_function ;;
      *) help_function ;;
   esac
done

if [ "${build_type}" = "release" ] ; then
  PKGCONG="GhostBSD"
elif [ "${build_type}" = "unstable" ] ; then
  PKGCONG="GhostBSD_Unstable"
else
  printf "\t-b Build type: unstable or release"
  exit 1
fi

# validate desktop packages
if [ ! -f "${cwd}/packages/${desktop}" ] ; then
  echo "The packages/${desktop} file does not exist."
  echo "Please create a package file named '${desktop}'and place it under packages/."
  echo "Or use a valide desktop below:"
  echo "$desktop_list"
  echo "Usage: ./build.sh -d desktop"
  exit 1
fi

# validate desktop
if [ ! -f "${cwd}/desktop_config/${desktop}.sh" ] ; then
  echo "The desktop_config/${desktop}.sh file does not exist."
  echo "Please create a config file named '${desktop}.sh' like these config:"
  echo "$desktop_config_list"
  exit 1
fi

if [ "${desktop}" != "mate" ] ; then
  DESKTOP=$(echo "${desktop}" | tr '[:lower:]' '[:upper:]')
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
export release
cdroot="${livecd}/cdroot"
liveuser="ghostbsd"
export liveuser

time_stamp=""
release_stamp=""
label="GhostBSD"

workspace()
{
  umount ${base_packages} >/dev/null 2>/dev/null || true
  umount ${software_packages} >/dev/null 2>/dev/null || true
  umount ${release}/dev >/dev/null 2>/dev/null || true
  zpool destroy ghostbsd >/dev/null 2>/dev/null || true
  umount ${release} >/dev/null 2>/dev/null || true
  if [ -d "${cdroot}" ] ; then
    chflags -R noschg ${cdroot}
    rm -rf ${cdroot}
  fi
  mdconfig -d -u 0 >/dev/null 2>/dev/null || true
  if [ -f "${livecd}/pool.img" ] ; then
    rm ${livecd}/pool.img
  fi
  mkdir -p ${livecd} ${base} ${iso} ${software_packages} ${base_packages} ${release}
  truncate -s 6g ${livecd}/pool.img
  mdconfig -f ${livecd}/pool.img -u 0
  zpool create ghostbsd /dev/md0
  zfs set mountpoint=${release} ghostbsd
  zfs set compression=lz4 ghostbsd
}

base()
{
  mkdir -p ${release}/etc
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${base_packages} ${release}/var/cache/pkg
  pkg-static -r ${release} -R "${cwd}/pkg/" install -y -r ${PKGCONG} \
    os-generic-kernel os-generic-userland os-generic-userland-lib32

  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  touch ${release}/etc/fstab
  mkdir ${release}/cdrom
}

set_ghostbsd_version()
{
  version="-$(cat ${release}/etc/version)"
  isopath="${iso}/${label}${version}${release_stamp}${time_stamp}${community}.iso"
}

packages_software()
{
  if [ "${build_type}" = "unstable" ] ; then
    cp pkg/GhostBSD_Unstable.conf ${release}/etc/pkg/GhostBSD.conf
  fi
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${software_packages} ${release}/var/cache/pkg
  mount -t devfs devfs ${release}/dev
  pkg_list="$(cat "${cwd}/packages/${desktop}")"
  echo "$pkg_list" | xargs pkg -c ${release} install -y
  mkdir -p ${release}/compat/linux/proc
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
}

fetch_x_drivers_packages()
{
  if [ "${build_type}" = "release" ] ; then
    pkg_url=$(pkg-static -R pkg/ -vv | grep '/stable' | cut -d '"' -f2)
  else
    pkg_url=$(pkg-static -R pkg/ -vv | grep '/unstable' | cut -d '"' -f2)
  fi
  mkdir ${release}/xdrivers
  yes | pkg -R "${cwd}/pkg/" update
  echo """$(pkg -R "${cwd}/pkg/" rquery -x -r ${PKGCONG} '%n %n-%v.pkg' 'nvidia-driver' | grep -v libva)""" > ${release}/xdrivers/drivers-list
  pkg_list="""$(pkg -R "${cwd}/pkg/" rquery -x -r ${PKGCONG} '%n-%v.pkg' 'nvidia-driver' | grep -v libva)"""
  for line in $pkg_list ; do
    fetch -o ${release}/xdrivers "${pkg_url}/All/$line"
  done
}

rc()
{
  chroot ${release} touch /etc/rc.conf
  chroot ${release} sysrc hostname='livecd'
  chroot ${release} sysrc zfs_enable="YES"
  chroot ${release} sysrc kld_list="linux linux64 cuse fusefs"
  chroot ${release} sysrc linux_enable="YES"
  chroot ${release} sysrc devfs_enable="YES"
  chroot ${release} sysrc devfs_system_ruleset="devfsrules_common"
  chroot ${release} sysrc moused_enable="YES"
  chroot ${release} sysrc dbus_enable="YES"
  chroot ${release} sysrc lightdm_enable="NO"
  chroot ${release} sysrc webcamd_enable="YES"
  chroot ${release} sysrc ipfw_enable="YES"
  chroot ${release} sysrc firewall_enable="YES"
  chroot ${release} sysrc cupsd_enable="YES"
  chroot ${release} sysrc avahi_daemon_enable="YES"
  chroot ${release} sysrc avahi_dnsconfd_enable="YES"
  chroot ${release} sysrc ntpd_enable="YES"
  chroot ${release} sysrc ntpd_sync_on_start="YES"
}

ghostbsd_config()
{
  # echo "gop set 0" >> ${release}/boot/loader.rc.local
  mkdir -p ${release}/usr/local/share/ghostbsd
  echo "${desktop}" > ${release}/usr/local/share/ghostbsd/desktop
  # bypass automount for live iso
  mv ${release}/usr/local/etc/devd/automount_devd.conf ${release}/usr/local/etc/devd/automount_devd.conf.skip
  mv ${release}/usr/local/etc/devd/automount_devd_localdisks.conf ${release}/usr/local/etc/devd/automount_devd_localdisks.conf.skip
  # Mkdir for linux compat to ensure /etc/fstab can mount when booting LiveCD
  chroot ${release} mkdir -p /compat/linux/dev/shm
  # Add /boot/entropy file
  chroot ${release} touch /boot/entropy
  # default GhostBSD to local time instead of UTC
  chroot ${release} touch /etc/wall_cmos_clock
}

desktop_config()
{
  # run config for GhostBSD flavor
  sh "${cwd}/desktop_config/${desktop}.sh"
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
  cd "${cwd}" && zpool export ghostbsd && while zpool status ghostbsd >/dev/null; do :; done 2>/dev/null
}

image()
{
  cd script
  sh mkisoimages.sh -b $label "$isopath" ${cdroot}
  cd -
  ls -lh "$isopath"
  cd ${iso}
  shafile=$(echo "${isopath}" | cut -d / -f6).sha256
  torrent=$(echo "${isopath}" | cut -d / -f6).torrent
  tracker1="http://tracker.openbittorrent.com:80/announce"
  tracker2="udp://tracker.opentrackr.org:1337"
  tracker3="udp://tracker.coppersurfer.tk:6969"
  echo "Creating sha256 \"${iso}/${shafile}\""
  sha256 "$(echo "${isopath}" | cut -d / -f6)" > "${iso}/${shafile}"
  transmission-create -o "${iso}/${torrent}" -t ${tracker1} -t ${tracker2} -t ${tracker3} "${isopath}"
  chmod 644 "${iso}/${torrent}"
  cd -
}

workspace
base
set_ghostbsd_version
packages_software
fetch_x_drivers_packages
rc
desktop_config
ghostbsd_config
uzip
ramdisk
boot
image
