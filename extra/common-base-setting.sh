#!/bin/sh

set -e -u

patch_etc_files()
{
  cat ${cwd}/extra/common-base-setting/patches/boot/loader.conf.extra >> ${release}/boot/loader.conf
  cat ${cwd}/extra/common-base-setting/patches/etc/devfs.rules.extra >> ${release}/etc/devfs.rules
  cat ${cwd}/extra/common-base-setting/patches/etc/fstab.extra >> ${release}/etc/fstab
  mkdir -p ${release}/compat/linux/sys
  mkdir -p ${release}/compat/linux/dev/shm
  mkdir -p ${release}/compat/linux/sys
}

setup_base()
{
  patch_etc_files
}
