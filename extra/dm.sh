#!/bin/sh

set -e -u

lightdm_setup()
{
   if [ "${desktop}" == "xfce" ] ; then
    sed -i '' "s@#user-session=default@user-session=xfce@" ${release}/usr/local/etc/lightdm/lightdm.conf
    if [ -f ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf ] ; then
      echo "indicators=~host;~spacer;~clock;~spacer;~session;~language;~a11y;~sound;~power" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
      echo "background=/usr/local/share/backgrounds/ghostbsd/Tidepool_Sunset.jpg" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
      echo "theme-name=Vimix-Dark" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
      echo -e "icon-theme-name=Vivacious-Colors-Full-Dark\n" >> ${release}/usr/local/etc/lightdm/lightdm-gtk-greeter.conf
    fi
  elif [ "${desktop}" == "mate" ] ; then
    sed -i '' "s@#greeter-session=example-gtk-gnome@greeter-session=slick-greeter@" ${release}/usr/local/etc/lightdm/lightdm.conf
    sed -i '' "s@#user-session=default@user-session=mate@" ${release}/usr/local/etc/lightdm/lightdm.conf
    cp extra/dm/slick-greeter.conf ${release}/usr/local/etc/lightdm/slick-greeter.conf
    cp extra/dm/msd-background-helper ${release}/usr/local/bin/msd-background-helper
    chmod +x ${release}/usr/local/bin/msd-background-helper
    cp extra/dm/msd-background-helper.desktop ${release}/usr/local/etc/xdg/autostart/msd-background-helper.desktop
  fi
  setup_xinit
}

gdm_setup()
{
  echo 'gdm_enable="YES"' >> ${release}/etc/rc.conf
  setup_xinit
}

sddm_setup()
{
  echo 'sddm_enable="YES"' >> ${release}/etc/rc.conf
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
 elif [ "${desktop}" == "kde" ] ; then
    echo "exec ck-launch-session startplasmacompositor"> ${release}/usr/home/${liveuser}/.xinitrc
    echo "exec ck-launch-session startplasmacompositor" > ${release}/root/.xinitrc
  fi
}
