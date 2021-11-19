#!/usr/bin/env sh

set -e -u

cwd="$(realpath | sed 's|/scripts||g')"
export cwd
# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

kernrel="$(uname -r)"

case $kernrel in
  '13.0-STABLE') ;;
  *)
    echo "Using wrong kernel release. Use GhostBSD 20.04 or later to build iso."
    exit 1
    ;;
esac

desktop_list=$(find packages -type f | cut -d '/' -f2 | tr -s '\n' ' ')
helpFunction()
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
      'h') helpFunction ;;
      '?') helpFunction ;;
      *) helpFunction ;;
   esac
done


if [ "${build_type}" = "release" ] ; then
  PKGCONG="GhostBSD_PKG"
elif [ "${build_type}" = "unstable" ] ; then
  PKGCONG="GhostBSD_Unstable"
else
  printf "\t-b Build type: unstable or release"
  exit 1
fi


validate_desktop()
{
  if [ ! -f "${cwd}/packages/${desktop}" ] ; then
    echo "Invalid choice specified"
    echo "Possible choices are:"
    echo "$desktop_list"
    echo "Usage: ./build.sh mate"
    exit 1
  fi
}

validate_desktop

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
cdroot="${livecd}/cdroot"
liveuser="ghostbsd"

time_stamp=""
release_stamp=""
label="GhostBSD"

workspace()
{
  umount ${base_packages} >/dev/null 2>/dev/null || true
  umount ${software_packages} >/dev/null 2>/dev/null || true
  umount devfs >/dev/null 2>/dev/null || true
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
  pkg-static -r ${release} -R "${cwd}/pkg/" -C ${PKGCONG} install -y \
    os-generic-kernel os-generic-userland os-generic-userland-lib32 \
    os-generic-userland-devtools

  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  touch ${release}/etc/fstab
  mkdir ${release}/cdrom
}


set_ghostbsd_version()
{
  echo "Get the GhostBSD version file"
  if [ "${build_type}" = "release" ] ; then
    pkg_url=$(pkg-static -R pkg/ -vv | grep '/stable' | cut -d '"' -f2)
  else
    pkg_url=$(pkg-static -R pkg/ -vv | grep '/unstable' | cut -d '"' -f2)
  fi
  version_url="${pkg_url}/version"
  cd ${release}/etc
  fetch "${version_url}"
  cd -
  version="-$(curl "${version_url}")"
  isopath="${iso}/${label}${version}${release_stamp}${time_stamp}${community}.iso"
}


packages_software()
{
  if [ "${build_type}" = "unstable" ] ; then
    cp pkg/GhostBSD_TEST.conf ${release}/etc/pkg/GhostBSD.conf
  fi
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${software_packages} ${release}/var/cache/pkg
  mount -t devfs devfs ${release}/dev
  # cat "${cwd}/packages/${desktop}" |
  xargs pkg -c ${release} install -y < "${cwd}/packages/${desktop}"
  mkdir -p ${release}/compat/linux/proc
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
}

rc()
{
  # The 2 next line are to be remove when when the upgrade to FreeBSD rc.d
  # is completed
  chroot ${release} touch /boot/loader.conf
  chroot ${release} sysrc -f /boot/loader.conf rc_system="bsdrc"
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

user()
{
  chroot ${release} pw usermod -s /usr/local/bin/fish -n root
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
  . "${cwd}/extra/common-live-setting.sh"
  . "${cwd}/extra/common-base-setting.sh"
  . "${cwd}/extra/dm.sh"
  . "${cwd}/extra/finalize.sh"
  . "${cwd}/extra/autologin.sh"
  . "${cwd}/extra/gitpkg.sh"
  . "${cwd}/extra/setuser.sh"
  set_live_system
  ## git_gbi is for development testing and gbi should be
  ## remove from the package list to avoid conflict
  # git_pc_sysinstall
  git_gbi
  git_install_station
  setup_base
  lightdm_setup
  setup_liveuser
  setup_autologin
  final_setup
  echo "gop set 0" >> ${release}/boot/loader.rc.local
  mkdir -p ${release}/usr/local/share/ghostbsd
  echo "${desktop}" > ${release}/usr/local/share/ghostbsd/desktop
  echo "${liveuser}" > ${release}/usr/local/share/ghostbsd/liveuser
  # bypass automount for live
  mv ${release}/usr/local/etc/devd/automount_devd.conf ${release}/usr/local/etc/devd/automount_devd.conf.skip
  # Mkdir for linux compat to ensure /etc/fstab can mount when booting LiveCD
  chroot ${release} mkdir -p /compat/linux/dev/shm
  # Add /boot/entropy file
  chroot ${release} touch /boot/entropy
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
user
rc
extra_config
uzip
ramdisk
boot
image
