#!/bin/sh

set -e -u

base_overrides()
{
  cp -R ${cwd}/systems/trueos/extra/common-base-setting/override/* ${release}/
}


patch_etc_files()
{
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/boot/loader.conf.extra >> ${release}/boot/loader.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/profile.extra >> ${release}/etc/profile
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/devfs.rules.extra >> ${release}/etc/devfs.rules
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/sysctl.conf.extra >> ${release}/etc/sysctl.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/fstab.extra >> ${release}/etc/fstab
  cd ${release}/etc/
  patch < ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/login.conf.diff
  cd -
  chroot ${release} cap_mkdb /etc/login.conf
}

packages_settings()
{
  #set htmlview alternative to firefox for cups
  if [ -e ${release}/usr/local/bin/firefox ] ; then
    update-alternatives --altdir ${release}/usr/local/etc/alternatives --install ${release}/usr/local/bin/htmlview htmlview ${release}/usr/local/bin/firefox 50
  fi
}

setup_base()
{
  base_overrides
  patch_etc_files
  packages_settings
}
