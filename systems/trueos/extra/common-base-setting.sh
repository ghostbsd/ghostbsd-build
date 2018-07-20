#!/bin/sh

base_overrides()
{
  cp -R extra/common-base-setting/override/* ${release}/
}


patch_etc_files()
{
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/boot/loader.conf.extra >> ${release}/boot/loader.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/profile.extra >> ${release}/etc/profile
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/devfs.rules.extra >> ${release}/etc/devfs.rules
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/make.conf.extra >> ${release}/etc/make.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/rc.conf.extra >> ${release}/etc/rc.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/devd.conf.extra >> ${release}/etc/devd.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/sysctl.conf.extra >> ${release}/etc/sysctl.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/fstab.extra >> ${release}/etc/fstab
}

local_files()
{
  # cp ${cwd}/systems/trueos/extra/common-base-setting/etc/grub.d/10_kghostbsd ${release}/usr/local/etc/grub.d/10_kghostbsd
  #sed -i "" -e 's/"\/usr\/local\/sbin\/beadm"/"\/usr\/local\/etc\/grub.d\/10_kghostbsd"/g' ${release}/usr/local/etc/grub.d/10_kfreebsd
  # Adding kern.vty=vt to 10_kfreebsd
  sed -i '' '/set kFreeBSD.vfs.root.mountfrom.options=rw/a\
\	set kFreeBSD.kern.vty=vt\
\	set kFreeBSD.hw.psm.synaptics_support="1"\
' ${release}/usr/local/etc/grub.d/10_kfreebsd
  # Replassing FreeBSD by GhostBSD
  sed -i '' 's/"FreeBSD"/"GhostBSD"/g' ${release}/usr/local/etc/grub.d/10_kfreebsd
}

packages_settings()
{
  #set htmlview alternative to firefox for cups
  if [ -e ${release}/usr/local/bin/firefox ] ; then
    update-alternatives --altdir ${release}/usr/local/etc/alternatives --install ${release}/usr/local/bin/htmlview htmlview ${release}/usr/local/bin/firefox 50
  fi
}

# copy files from override to FreeBSD base system
base_overrides
# patch files from etc
patch_etc_files
# apply packages settings
# packages_settings
local_files

