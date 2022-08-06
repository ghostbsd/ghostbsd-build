#!/bin/sh

set -e -u

lightdm_setup()
{
  sed -i '' "s@#greeter-session=example-gtk-gnome@greeter-session=slick-greeter@" "${release}/usr/local/etc/lightdm/lightdm.conf"
  if [ "${desktop}" = "xfce" ] ; then
    sed -i '' "s@#user-session=default@user-session=xfce@" "${release}/usr/local/etc/lightdm/lightdm.conf"
  elif [ "${desktop}" = "mate" ] ; then
    sed -i '' "s@#user-session=default@user-session=mate@" "${release}/usr/local/etc/lightdm/lightdm.conf"
  fi
  setup_xinit

}

setup_xinit()
{
  if [ "${desktop}" = "mate" ] ; then
    echo "gsettings set org.mate.SettingsDaemon.plugins.housekeeping active true &" > "${release}/usr/home/${liveuser}/.xinitrc"
    {
      echo "gsettings set org.mate.screensaver lock-enabled false &"
      echo "gsettings set org.mate.lockdown disable-lock-screen true &"
      echo "gsettings set org.mate.lockdown disable-user-switching true &"
    } >> "${release}/usr/home/${liveuser}/.xinitrc"
    echo "exec ck-launch-session mate-session" >> "${release}/usr/home/${liveuser}/.xinitrc"
    echo "exec ck-launch-session mate-session" > "${release}/root/.xinitrc"
  elif [ "${desktop}" = "xfce" ] ; then
    echo "exec ck-launch-session startxfce4" > "${release}/usr/home/${liveuser}/.xinitrc"
    echo "exec ck-launch-session startxfce4" > "${release}/root/.xinitrc"
  fi
}
