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
      cp -Rf ${BASEDIR}/etc/rc.d/$tocopy ${BASELOCALDIR}/share/ghostbsd/common-live-settings/base/backup/etc/rc.d/
    fi
  done
}

freebsd_overrides()
{
  cp -Rf ${BASEDIR}/usr/local/share/ghostbsd/common-live-settings/base/override/root/* ${BASEDIR}/root
  cp -Rf ${BASEDIR}/usr/local/share/ghostbsd/common-live-settings/base/override/etc/* ${BASEDIR}/etc
  # rebuild login database because one override was login.conf
  chroot ${BASEDIR} cap_mkdb /etc/login.conf
}

copy_files_in()
{
  cp -Rf ${BASEDIR}/usr/local/share/ghostbsd/common-live-settings/etc/* ${BASEDIR}/etc
}

setup_root_boot()
{
sed -i "" 's|ttyv0	"/usr/libexec/getty Pc"		xterm	on  secure|ttyv0	"/usr/libexec/getty root"		xterm	on  secure|g' ${BASEDIR}/etc/ttys
echo "netcardmgr" >> ${BASEDIR}/root/.login
echo "startx" >> ${BASEDIR}/root/.login
# echo "sh sysconfig.sh" >> ${BASEDIR}/root/.login
}

backup_freebsd
freebsd_overrides
copy_files_in
# setup_root_boot
