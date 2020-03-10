#!/usr/bin/env sh

set -e -u

liveuser=ghostbsd

if [ "${desktop}" != "mate" ] ; then
  DESKTOP=$(echo ${desktop} | tr [a-z] [A-Z])
  community="-${DESKTOP}"
else
  community=""
fi

# stage=$2

workdir="/usr/local"
livecd="${workdir}/ghostbsd-build"
base="${livecd}/base"
iso="${livecd}/iso"
software_packages="${livecd}/software_packages"
base_packages="${livecd}/base_packages"
release="${livecd}/release"
cdroot="${livecd}/cdroot"

# version="20.01"
if [ "${release_type}" == "release" ] ; then
  version=`date "+-%y.%m"`
  time_stamp=""
else
  version=""
  time_stamp=`date "+-%Y-%m-%d"`
fi
release_stamp=""
# release_stamp="-RC4"

label="GhostBSD"
isopath="${iso}/${label}${version}${release_stamp}${time_stamp}${community}.iso"
if [ "$desktop" = "mate" ] ; then
  union_dirs=${union_dirs:-"bin boot compat dev etc include lib libdata libexec man media mnt net proc rescue root sbin share tests tmp usr/home usr/local/etc usr/local/share/mate-panel var www"}
elif [ "$desktop" = "kde" ] ; then
  union_dirs=${union_dirs:-"bin boot compat dev etc include lib libdata libexec man media mnt net proc rescue root sbin share tests tmp usr/home usr/local/etc usr/local/share/plasma var www"}
else
  union_dirs=${union_dirs:-"bin boot compat dev etc include lib libdata libexec man media mnt net proc rescue root sbin share tests tmp usr/home usr/local/etc var www"}
fi

workspace()
{
  if [ -d ${release}/var/cache/pkg ]; then
    if [ "$(ls -A ${release}/var/cache/pkg)" ]; then
      umount ${release}/var/cache/pkg
    fi
  fi

  if [ -d "${release}" ] ; then
    if [ -d ${release}/dev ]; then
      if [ "$(ls -A ${release}/dev)" ]; then
        umount ${release}/dev
      fi
    fi
    chflags -R noschg ${release}
    rm -rf ${release}
  fi

  if [ -d "${cdroot}" ] ; then
    chflags -R noschg ${cdroot}
    rm -rf ${cdroot}
  fi
  mkdir -p ${livecd} ${base} ${iso} ${software_packages} ${base_packages} ${release}
}

base()
{
  mkdir -p ${release}/etc
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${base_packages} ${release}/var/cache/pkg
  pkg-static -r ${release} -R ${cwd}/repos/usr/local/etc/pkg/repos/ -C GhostBSD install -y -g os-generic-kernel os-generic-userland os-generic-userland-lib32 os-generic-userland-devtools

  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  touch ${release}/etc/fstab
  mkdir ${release}/cdrom
}

packages_software()
{
  cp -R ${cwd}/repos/ ${release}
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${software_packages} ${release}/var/cache/pkg
  mount -t devfs devfs ${release}/dev
  cat ${cwd}/packages/common-packages | xargs pkg -c ${release} install -y 
  case $desktop in
    mate)
      cat ${cwd}/packages/mate | xargs pkg -c ${release} install -y ;;
    xfce)
      cat ${cwd}/packages/xfce | xargs pkg -c ${release} install -y ;;
    cinnamon)
      cat ${cwd}/packages/cinnamon | xargs pkg-static -c ${release} install -y ;;
    kde)
      cat ${cwd}/packages/kde | xargs pkg -c ${release} install -y ;;
  esac
  mkdir -p ${release}/compat/linux/proc
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg

  cp -R ${cwd}/repos/ ${release}

}

rc()
{
  chroot ${release} sysrc -f /etc/rc.conf root_rw_mount="NO"
  chroot ${release} sysrc -f /etc/rc.conf hostname='livecd'
  chroot ${release} sysrc -f /etc/rc.conf sendmail_enable="NONE"
  chroot ${release} sysrc -f /etc/rc.conf sendmail_submit_enable="NO"
  chroot ${release} sysrc -f /etc/rc.conf sendmail_outbound_enable="NO"
  chroot ${release} sysrc -f /etc/rc.conf sendmail_msp_queue_enable="NO"
  # DEVFS rules
  chroot ${release} sysrc -f /etc/rc.conf devfs_system_ruleset="devfsrules_common"
  # Load the following kernel modules
  chroot ${release} sysrc -f /etc/rc.conf kld_list="linux linux64 cuse"
  # remove kldload_nvidia on rc.conf
  ( echo 'g/kldload_nvidia="nvidia-modeset nvidia"/d' ; echo 'wq' ) | ex -s ${release}/etc/rc.conf
  chroot ${release} rc-update add devfs default
  chroot ${release} rc-update add moused default
  chroot ${release} rc-update add dbus default
  chroot ${release} rc-update add hald default
  chroot ${release} rc-update add webcamd default
  chroot ${release} rc-update add powerd default
  # remove netmount from default
  chroot ${release} rc-update delete netmount default
  # chroot ${release} rc-update delete vboxguest default
  # chroot ${release} rc-update delete vboxservice default
  chroot ${release} rc-update add cupsd default
  chroot ${release} rc-update add avahi-daemon default
  chroot ${release} rc-update add avahi-dnsconfd default
  chroot ${release} rc-update add ntpd default
  chroot ${release} sysrc -f /etc/rc.conf ntpd_sync_on_start="YES"
}

user()
{
  chroot ${release} pw useradd ${liveuser} \
  -c "GhostBSD Live User" -d "/usr/home/${liveuser}"\
  -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
}

extra_config()
{
  . ${cwd}/extra/common-live-setting.sh
  . ${cwd}/extra/common-base-setting.sh
  . ${cwd}/extra/setuser.sh
  . ${cwd}/extra/dm.sh
  . ${cwd}/extra/finalize.sh
  . ${cwd}/extra/autologin.sh
  . ${cwd}/extra/gitpkg.sh
  . ${cwd}/extra/mate-live-settings.sh
  set_live_system
  # git_pc_sysinstall
  ## git_gbi is for development testing and gbi should be
  ## remove from the package list to avoid conflict
  # git_gbi
  setup_liveuser
  setup_base
  if [ "${desktop}" == "kde" ] ; then
    setup_xinit
  elif [ "${desktop}" == "xfce" ] ; then
    lightdm_setup
    # git_xfce_settings
  elif [ "${desktop}" == "mate" ] ; then
    lightdm_setup
    mate_schemas
  else
    lightdm_setup
  fi
  setup_autologin
  # setup_xinit
  final_setup
  echo "gop set 0" >> ${release}/boot/loader.rc.local
  # To fix lightdm crashing to be remove on the new base update.
  sed -i '' -e 's/memorylocked=128M/memorylocked=256M/' ${release}/etc/login.conf
  chroot ${release} cap_mkdb /etc/login.conf
  mkdir -p ${release}/usr/local/share/ghostbsd
  echo "${desktop}" > ${release}/usr/local/share/ghostbsd/desktop
}

xorg()
{
  if [ -n "${desktop}" ] ; then
    install -o root -g wheel -m 755 "${cwd}/xorg/bin/xconfig" "${release}/usr/local/bin/"
    install -o root -g wheel -m 755 "${cwd}/xorg/rc.d/xconfig" "${release}/usr/local/etc/rc.d/"
    if [ -f "${release}/sbin/openrc-run" ] ; then
      install -o root -g wheel -m 755 "${cwd}/xorg/init.d/xconfig" "${release}/usr/local/etc/init.d/"
    fi
    if [ ! -d "${release}/usr/local/etc/X11/cardDetect/" ] ; then
      mkdir -p ${release}/usr/local/etc/X11/cardDetect
    fi
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.vesa" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.scfb" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.virtualbox" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.vmware" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.nvidia" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.intel" "${release}/usr/local/etc/X11/cardDetect/"
    install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.modesetting" "${release}/usr/local/etc/X11/cardDetect/"
  fi
}

uzip()
{
  umount ${release}/dev
  install -o root -g wheel -m 755 -d "${cdroot}"
  mkdir "${cdroot}/data"
  # makefs -t ffs -m 4000m -f '10%' -b '10%' "${cdroot}/data/usr.ufs" "${release}/usr"
  makefs -t ffs -f '10%' -b '10%' "${cdroot}/data/usr.ufs" "${release}/usr"
  # makefs "${cdroot}/data/usr.ufs" "${release}/usr"
  mkuzip -o "${cdroot}/data/usr.uzip" "${cdroot}/data/usr.ufs"
  rm -r "${cdroot}/data/usr.ufs"
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
  cp ${release}/etc/login.conf ${ramdisk_root}/etc/login.conf
  makefs -b '10%' "${cdroot}/data/ramdisk.ufs" "${ramdisk_root}"
  gzip "${cdroot}/data/ramdisk.ufs"
  rm -rf "${ramdisk_root}"
}

mfs()
{
  for dir in ${union_dirs}; do
    echo ${dir} >> ${cdroot}/data/uniondirs
    cd ${release} && tar -cpzf ${cdroot}/data/mfs.tgz ${union_dirs}
  done
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
  cd ${cdroot}
  cd "${cwd}"
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
