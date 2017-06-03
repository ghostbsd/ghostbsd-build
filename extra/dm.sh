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

lightdm_setup()

{
  if [ -f ${BASEDIR}/usr/local/etc/lightdm/lightdm.conf ] ; then
    sed -i "" '/#exit-on-failure=false/a\
autologin-user=ghostbsd\
autologin-user-timeout=0\
' ${BASEDIR}/usr/local/etc/lightdm/lightdm.conf
  fi

  if [ -f ${BASEDIR}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf ] ; then
    #echo "background=/usr/local/share/backgrounds/ghostbsd/White-Trees-Empire.jpg" >> ${BASEDIR}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
    #echo "user-background=true" >> ${BASEDIR}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
    #echo "theme-name=Ambiance-Blackout-Flat-Aqua" >> ${BASEDIR}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
    #echo "icon-theme-name=Vivacious-Colors-Full-Dark" >> ${BASEDIR}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
  fi
  echo 'lightdm_enable="YES"' >> ${BASEDIR}/etc/rc.conf
}

case "${PACK_PROFILE}" in
  mate)
    lightdm_setup
    ;;
  xfce)
    lightdm_setup
    ;;
  *)
    ;;
esac
