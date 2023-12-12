#!/bin/sh

set -e -u

patch_etc_files()
{
  cat "${cwd}/common_config/base-setting/patches/etc/devfs.rules.extra" >> "${release}/etc/devfs.rules"
  cat "${cwd}/common_config/base-setting/patches/etc/fstab.extra" >> "${release}/etc/fstab"
  mkdir -p "${release}/compat/linux/dev/shm"
  mkdir -p "${release}/compat/linux/sys"
}