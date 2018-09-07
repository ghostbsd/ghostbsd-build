#!/usr/bin/env sh

cwd="`realpath | sed 's|/scripts||g'`"
liveuser=ghostbsd
systems=$1
desktop=$2
workdir="/usr/local"
livecd="${workdir}/ghostbsd-build/${systems}"
base="${livecd}/base"
software_packages="${livecd}/software_packages"
base_packages="${livecd}/base_packages"
release="${livecd}/release"
cdroot="${livecd}/cdroot"
# version="18.09"
version=""
timestamp=`date "+-%Y-%m-%d-%H-%M"`
label="GhostBSD"
union_dirs=${union_dirs:-"boot cdrom dev etc libexec media mnt root tmp usr/home usr/local/etc usr/local/share/mate-panel var"}
kernrel="`uname -r`"

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Only run with GhostBSD18 or TrueOS 18.06 or later.
case $kernrel in
  '12.0-CURRENT')
    echo " Using correct kernel release" 1>&2
    ;;
  *)
   echo "Using wrong kernel release. Use TrueOS 18.06 or GhostBSD 18 to build iso."
   exit 1
   ;;
esac

display_usage()
{
  echo "You must specify a systems at minimum!"
  echo "Possible choices are:"
  ls ${cwd}/systems
  echo "Usage: ./build.sh trueos"
  exit 1
}

validate_systems()
{
  if [ ! -d "${cwd}/systems/${systems}" ] ; then
    display_usage
  fi
}

validate_desktop()
{
  if [ ! -f "${cwd}/systems/${systems}/packages/${desktop}" ] ; then
    echo "Invalid choice specified"
    echo "Possible choices are:"
    ls ${cwd}/systems/${systems}/packages
    echo "Usage: ./build.sh trueos mate"
    exit 1
  fi
}

# We must choose a systems at minimum
if [ -z "${systems}" ] ; then
  echo "You must specify a systems!"
  echo "Possible choices are:"
  ls ${cwd}/systems
  echo "Usage: ./build.sh trueos"
  exit 1
else
  validate_systems
fi

# Validate package selection if chosen
if [ -z "${desktop}" ] ; then
  desktop=mate
else
  validate_desktop
fi


if [ "${desktop}" == "xfce" ] ; then
  community="-XFCE"
else
  community=""
fi


isopath="${livecd}/${label}${version}${timestamp}${community}.iso"

workspace()
{
  umount ${release}/var/cache/pkg >/dev/null 2>/dev/null
  if [ -d "${livecd}" ] ;then
    chflags -R noschg ${release} ${cdroot} >/dev/null 2>/dev/null
    rm -rf ${release} ${cdroot} >/dev/null 2>/dev/null
  fi
  mkdir -p ${livecd} ${base} ${software_packages} ${base_packages} ${release} >/dev/null 2>/dev/null
}

base()
{
  case $systems in
    trueos)
              mkdir ${release}/etc
              cp /etc/resolv.conf ${release}/etc/resolv.conf
              mkdir -p ${release}/var/cache/pkg
              mount_nullfs ${base_packages} ${release}/var/cache/pkg
              pkg-static -R ${cwd}/systems/trueos/repos/usr/local/etc/pkg/repos/ -C GhostBSD-base search -q FreeBSD | grep -v -E "(-doc|-debug|-profile)" | xargs pkg-static -r ${release} -R ${cwd}/systems/trueos/repos/usr/local/etc/pkg/repos/ -C GhostBSD-base install -y -g
              rm ${release}/etc/resolv.conf
              umount ${release}/var/cache/pkg;;
    freebsd)
              if [ ! -f "${base}/base.txz" ] ; then
                cd ${base}
                fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.2-RELEASE/base.txz
              fi
              if [ ! -f "${base}/kernel.txz" ] ; then
                cd ${base}
                fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.2-RELEASE/kernel.txz
              fi
              if [ ! -f "${base}/lib32.txz" ] ; then
                cd ${base}
                fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.2-RELEASE/lib32.txz
              fi
              cd ${base}
              tar -zxvf base.txz -C ${release}
              tar -zxvf kernel.txz -C ${release}
              tar -zxvf lib32.txz -C ${release};;
             *)
              exit 1;;
  esac
  touch ${release}/etc/fstab
  mkdir ${release}/cdrom
}

compress_packages()
{

}

packages_software()
{
  case $systems in
    trueos)
            cp -R ${cwd}/systems/trueos/repos/ ${release};;
    freebsd)
            cp -R ${cwd}/systems/freebsd/repos/ ${release};;
    *)
      ;;
  esac

  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir ${release}/var/cache/pkg
  mount_nullfs ${software_packages} ${release}/var/cache/pkg

  case $desktop in
      mate)
          cat ${cwd}/systems/${systems}/packages/mate | xargs pkg-static -c ${release} install -y ;;
      xfce)
          cat ${cwd}/systems/${systems}/packages/xfce | xargs pkg-static -c ${release} install -y ;;
  esac

  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg

  case $systems in
    trueos)
            cp -R ${cwd}/systems/trueos/repos/ ${release};;
    freebsd)
            cp -R ${cwd}/systems/freebsd/repos/ ${release};;
    *)
      ;;
  esac

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
  chroot ${release} sysrc -f /etc/rc.conf kld_list="geom_mirror geom_journal linux"
  if [ -f "${release}/sbin/openrc-run" ] ; then
      chroot ${release} sysrc -f /etc/rc.conf rc_interactive="YES"
    case $desktop in
       mate)
           chroot ${release} rc-update add devfs default
           chroot ${release} rc-update add moused default
           chroot ${release} rc-update add dbus default
           chroot ${release} rc-update add hald default
           chroot ${release} rc-update add xconfig default
           chroot ${release} rc-update add webcamd default
           chroot ${release} rc-update add vboxguest default
           chroot ${release} rc-update add vboxservice default
           chroot ${release} rc-update add cupsd default
           #chroot ${release} rc-update add lightdm default
           #chroot ${release} rc-update add xdm default
           #chroot ${release} sysrc -f /usr/local/etc/conf.d/xdm DISPLAYMANAGER="lightdm"
           ;;
      xfce)
           chroot ${release} rc-update add moused default
           chroot ${release} rc-update add dbus default
           chroot ${release} rc-update add hald default
           chroot ${release} rc-update add xconfig default
           #chroot ${release} rc-update add lightdm default
           #chroot ${release} rc-update add xdm default
           #chroot ${release} sysrc -f /usr/local/etc/conf.d/xdm DISPLAYMANAGER="lightdm"
           ;;
    esac
  else
    case $desktop in
      mate)
           chroot ${release} sysrc -f /etc/rc.conf moused_enable="YES"
           chroot ${release} sysrc -f /etc/rc.conf dbus_enable="YES"
           chroot ${release} sysrc -f /etc/rc.conf hald_enable="YES"
           #chroot ${release} sysrc -f /etc/rc.conf lightdm_enable="YES"
           chroot ${release} sysrc -f /etc/rc.conf xconfig_enable="YES" ;;
      xfce)
           chroot ${release} sysrc -f /etc/rc.conf moused_enable="YES"
           chroot ${release} sysrc -f /etc/rc.conf dbus_enable="YES"
           #chroot ${release} sysrc -f /etc/rc.conf lightdm_enable="YES"
           chroot ${release} sysrc -f /etc/rc.conf xconfig_enable="YES" ;;
    esac
  fi
}

user()
{
  chroot ${release} pw useradd ${liveuser} \
  -c "GhostBSD Live User" -d "/usr/home/${liveuser}" \
  -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
}

extra_config()
{
  case $systems in
    trueos)
        . ${cwd}/systems/trueos/extra/common-live-setting.sh
        . ${cwd}/systems/trueos/extra/common-base-setting.sh
        . ${cwd}/systems/trueos/extra/setuser.sh
        . ${cwd}/systems/trueos/extra/dm.sh
        . ${cwd}/systems/trueos/extra/finalize.sh
        . ${cwd}/systems/trueos/extra/autologin.sh
        . ${cwd}/systems/trueos/extra/gitpkg.sh
        set_live_system
        setup_liveuser
        setup_base
        #lightdm_setup
        setup_xinit
        setup_autologin
        git_pc_sysinstall
        ## git_gbi is for development testing and gbi should be
        ## remove from the package list to avoid conflict
        git_gbi
        final_setup
        ;;
    freebsd)
        . ${cwd}/systems/freebsd/extra/common-live-setting.sh
        . ${cwd}/systems/freebsd/extra/setuser.sh
        . ${cwd}/systems/freebsd/extra/dm.sh
        create_share_ghostbsd
        setup_liveuser
        #lightdm_setup
        ;;
    *)
      ;;
  esac
  echo "gop set 0" >> ${release}/boot/loader.rc.local
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
  fi
}

uzip()
{
  install -o root -g wheel -m 755 -d "${cdroot}"
  mkdir "${cdroot}/data"
  makefs "${cdroot}/data/system.ufs" "${release}"
  mkuzip -o "${cdroot}/data/system.uzip" "${cdroot}/data/system.ufs"
  rm -f "${cdroot}/data/system.ufs"
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
  tar -cf - --exclude boot/kernel boot | tar -xf - -C "${cdroot}"
  for kfile in kernel geom_uzip.ko nullfs.ko tmpfs.ko unionfs.ko; do
    tar -cf - boot/kernel/${kfile} | tar -xf - -C "${cdroot}"
  done
  cd "${cwd}"
  cp -R boot/ ${cdroot}/boot/
  mkdir ${cdroot}/etc
}

image()
{
  sh mkisoimages.sh -b $label $isopath ${cdroot}
  ls -lh $isopath
  cd ${livecd}
  md5 `echo ${isopath}|cut -d / -f6` > $(echo ${isopath}|cut -d / -f6).md5
  sha256 `echo ${isopath}| cut -d / -f6` > $(echo ${isopath}|cut -d / -f6).sha256
  cd -
}
