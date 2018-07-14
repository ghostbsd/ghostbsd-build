#!/bin/sh

set -e -u


backup_freebsd()
{
  # backup files from etc
  for tocopy in $(ls ${release}/usr/local/share/ghostbsd/common-live-settings/base/override/etc/rc.d) ; do
    if [ -f ${release}/etc/rc.d/$tocopy ]; then
      cp -Rf ${release}/etc/rc.d/$tocopy ${release}/usr/local/share/ghostbsd/common-live-settings/base/backup/etc/rc.d/
    fi
  done
}

freebsd_overrides()
{
  cp -Rf ${release}/usr/local/share/ghostbsd/common-live-settings/base/override/root/* ${release}/root
  #cp -Rf ${release}/usr/local/share/ghostbsd/common-live-settings/base/override/etc/* ${release}/etc
  # rebuild login database because one override was login.conf
  #chroot ${release} cap_mkdb /etc/login.conf
}

copy_files_in()
{
  cp -Rf ${release}/usr/local/share/ghostbsd/common-live-settings/etc/* ${release}/etc
}

create_share_ghostbsd()
{
  mkdir -p ${release}/usr/local/share/ghostbsd
  cp -R ${cwd}/distro/trueghost/extra/common-live-settings ${release}/usr/local/share/ghostbsd
  backup_freebsd
  freebsd_overrides
  copy_files_in
}