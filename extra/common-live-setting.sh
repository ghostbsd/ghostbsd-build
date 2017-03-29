#!/bin/sh

set -e -u

if [ -z "${LOGFILE:-}" ] ; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

mkdir ${BASELOCALDIR}/share/ghostbsd
cp -R common-live-setting ${BASELOCALDIR}/share/ghostbsd


backup_freebsd()
{
  # backup files from etc
  for tocopy in $(ls common-live-settings/base/override/etc/rc.d) ; do
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

setup_DM() {
  if [ -f ${BASEDIR}/usr/local/etc/slim.conf ] ; then
      sed -i '' -e "s/#auto_login          no/auto_login          yes/g"\
      -e  "s/#default_user        simone/default_user        root/g" \
      ${BASEDIR}/usr/local/etc/slim.conf
      echo 'sessiondir       /usr/local/share/xsessions/' >> ${BASEDIR}/usr/local/etc/slim.conf
    fi
}