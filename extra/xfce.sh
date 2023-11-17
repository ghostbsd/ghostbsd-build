#!/bin/sh

set -e -u

. "${cwd}/extra/common-live-setting.sh"
. "${cwd}/extra/common-base-setting.sh"
. "${cwd}/extra/dm.sh"
. "${cwd}/extra/finalize.sh"
. "${cwd}/extra/autologin.sh"
. "${cwd}/extra/gitpkg.sh"
. "${cwd}/extra/setuser.sh"

lightdm_setup()
{
  sed -i '' "s@#greeter-session=example-gtk-gnome@greeter-session=slick-greeter@" "${release}/usr/local/etc/lightdm/lightdm.conf"
  sed -i '' "s@#user-session=default@user-session=xfce@" "${release}/usr/local/etc/lightdm/lightdm.conf"
}

setup_xinit()
{
  echo "exec ck-launch-session startxfce4" > "${release}/usr/home/${liveuser}/.xinitrc"
  echo "exec ck-launch-session startxfce4" > "${release}/root/.xinitrc"
}



set_live_system
patch_etc_files

lightdm_setup
setup_xinit

community_setup_liveuser
community_setup_autologin
final_setup
