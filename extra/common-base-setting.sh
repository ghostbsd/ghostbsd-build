#!/bin/sh

base_overrides()
{
  cp -R extra/common-base-setting/override/* ${BASEDIR}/
}


patch_etc_files()
{
  cat extra/common-base-setting/patches/boot/loader.conf.extra >> ${BASEDIR}/boot/loader.conf
  cat extra/common-base-setting/patches/etc/profile.extra >> ${BASEDIR}/etc/profile
  cat extra/common-base-setting/patches/etc/devfs.rules.extra >> ${BASEDIR}/etc/devfs.rules
  cat extra/common-base-setting/patches/etc/make.conf.extra >> ${BASEDIR}/etc/make.conf
  cat extra/common-base-setting/patches/etc/rc.conf.extra >> ${BASEDIR}/etc/rc.conf
  cat extra/common-base-setting/patches/etc/devd.conf.extra >> ${BASEDIR}/etc/devd.conf
  cat extra/common-base-setting/patches/etc/sysctl.conf.extra >> ${BASEDIR}/etc/sysctl.conf
  cat extra/common-base-setting/patches/etc/fstab.extra >> ${BASEDIR}/etc/fstab
}

local_files()
{
  # cp extra/common-base-setting/etc/grub.d/10_kghostbsd ${BASEDIR}/usr/local/etc/grub.d/10_kghostbsd
  #sed -i "" -e 's/"\/usr\/local\/sbin\/beadm"/"\/usr\/local\/etc\/grub.d\/10_kghostbsd"/g' ${BASEDIR}/usr/local/etc/grub.d/10_kfreebsd
  # Adding kern.vty=vt to 10_kfreebsd
  sed -i '' '/set kFreeBSD.vfs.root.mountfrom.options=rw/a\
\	set kFreeBSD.kern.vty=vt\
\	set kFreeBSD.hw.psm.synaptics_support="1"\
' /usr/local/etc/grub.d/10_kfreebsd
  # Replassing FreeBSD by GhostBSD
  sed -i '' 's/"FreeBSD"/"GhostBSD"/g' /usr/local/etc/grub.d/10_kfreebsd
}

packages_settings()
{
  #set htmlview alternative to firefox for cups
  if [ -e ${BASEDIR}/usr/local/bin/firefox ] ; then
    update-alternatives --altdir ${BASEDIR}/usr/local/etc/alternatives --install ${BASEDIR}/usr/local/bin/htmlview htmlview ${BASEDIR}/usr/local/bin/firefox 50
  fi
}

# copy files from override to FreeBSD base system
base_overrides
# patch files from etc
patch_etc_files
# apply packages settings
#packages_settings
local_files

