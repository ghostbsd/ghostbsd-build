#!/bin/sh

set -e -u

lightdm_setup()
{
  if [ -f ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf ] ; then
    echo "indicators=~host;~spacer;~clock;~spacer;~session;~language;~a11y;~sound;~power" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
    echo "background=/usr/local/share/backgrounds/ghostbsd/Tidepool_Sunset.jpg" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
    echo "theme-name=Vimix-Dark" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
    echo -e "icon-theme-name=Vivacious-Colors-Full-Dark\n" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
  fi
  setup_xinit
}

gdm_setup()
{
  echo 'gdm_enable="YES"' >> ${release}/etc/rc.conf
  setup_xinit
}

setup_xinit()
{
  if [ "${desktop}" == "mate" ] ; then
    echo "exec ck-launch-session mate-session" > ${release}/usr/home/${liveuser}/.xinitrc
    echo "exec ck-launch-session mate-session" > ${release}/root/.xinitrc
  elif [ "${desktop}" == "xfce" ] ; then
    echo "exec ck-launch-session startxfce4" > ${release}/usr/home/${liveuser}/.xinitrc
    echo "exec ck-launch-session startxfce4" > ${release}/root/.xinitrc
  elif [ "${desktop}" == "cinnamon" ] ; then
    echo "exec ck-launch-session cinnamon-session" > ${release}/usr/home/${liveuser}/.xinitrc
    echo "exec ck-launch-session cinnamon-session" > ${release}/root/.xinitrc
  fi
}
