#!/bin/sh

set -e -u

patch_etc_files()
{
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/boot/loader.conf.extra >> ${release}/boot/loader.conf
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/profile.extra >> ${release}/etc/profile
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/devfs.rules.extra >> ${release}/etc/devfs.rules
  cat ${cwd}/systems/trueos/extra/common-base-setting/patches/etc/fstab.extra >> ${release}/etc/fstab
}

setup_base()
{
  patch_etc_files
}
