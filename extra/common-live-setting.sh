#!/bin/sh

set -e -u

if [ -z "${LOGFILE:-}" ] ; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

mkdir -p ${BASELOCALDIR}/share/ghostbsd
cp -R extra/common-live-settings ${BASELOCALDIR}/share/ghostbsd


backup_freebsd()
{
  # backup files from etc
  for tocopy in $(ls ${BASELOCALDIR}/share/ghostbsd/common-live-settings/base/override/etc/rc.d) ; do
    if [ -f ${BASEDIR}/etc/rc.d/$tocopy ]; then
      cp -af ${BASEDIR}/etc/rc.d/$tocopy ${BASELOCALDIR}/share/ghostbsd/common-live-settings/base/backup/etc/rc.d/
    fi
  done
}

freebsd_overrides()
{
  cp -af ${BASEDIR}/usr/local/share/ghostbsd/common-live-settings/base/override/* ${BASEDIR}/
  # rebuild login database because one override was login.conf
  chroot ${BASEDIR} cap_mkdb /etc/login.conf
}

copy_files_in()
{
    cp -af ${BASEDIR}/usr/local/share/ghostbsd/common-live-settings/etc/* ${BASEDIR}/etc
}

backup_freebsd
freebsd_overrides
copy_files_in
