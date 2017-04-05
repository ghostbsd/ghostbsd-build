#!/bin/sh

set -e -u

if [ -z "${LOGFILE:-}" ] ; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

slim_setup()
{
  if [ -f ${BASEDIR}/usr/local/etc/slim.conf ] ; then
    sed -i '' -e "s/#auto_login          no/auto_login          yes/g"\
    -e  "s/#default_user        simone/default_user        root/g" \
    ${BASEDIR}/usr/local/etc/slim.conf
    echo 'sessiondir       /usr/local/share/xsessions/' >> ${BASEDIR}/usr/local/etc/slim.conf
  fi
}

case "${PACK_PROFILE}" in
  mate)
    slim
    ;;
  xfce)
    slim
    ;;
  *)
    ;;
esac