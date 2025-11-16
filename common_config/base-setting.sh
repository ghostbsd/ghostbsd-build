#!/bin/sh
set -e -u
patch_etc_files()
{
  cat "${cwd}/common_config/base-setting/patches/etc/devfs.rules.extra" >> "${release}/etc/devfs.rules"
  cat "${cwd}/common_config/base-setting/patches/etc/fstab.extra" >> "${release}/etc/fstab"
  mkdir -p "${release}/compat/linux/dev/shm"
  mkdir -p "${release}/compat/linux/sys"
}

patch_loader_conf_d()
{
  local patches_dir="${cwd}/common_config/base-setting/patches/boot/loader.conf.d"
  
  if [ -d "${patches_dir}" ]; then
    echo "Applying loader.conf.d configurations..."
    mkdir -p "${release}/boot/loader.conf.d"
    cp -v "${patches_dir}"/*.conf "${release}/boot/loader.conf.d/" 2>/dev/null || true
    chmod 644 "${release}/boot/loader.conf.d"/*.conf 2>/dev/null || true
  fi
}
