#!/bin/sh

set -e -u

. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/gitpkg.sh"
. "${cwd}/common_config/setuser.sh"

lightdm_setup()
{
  sed -i '' "s@#greeter-session=example-gtk-gnome@greeter-session=slick-greeter@" "${release}/usr/local/etc/lightdm/lightdm.conf"
  sed -i '' "s@#user-session=default@user-session=mate@" "${release}/usr/local/etc/lightdm/lightdm.conf"
}

setup_xinit()
{
  echo "exec marco &" > "${release}/home/${live_user}/.xinitrc"
  echo "exec feh --bg-fill /usr/local/share/backgrounds/ghostbsd/Lake_View.jpg &" >> "${release}/home/${live_user}/.xinitrc"
  echo "exec sudo install-station" >> "${release}/home/${live_user}/.xinitrc"
  chmod 765 "${release}/home/${live_user}/.xinitrc"
  # root
  echo "exec marco &" > "${release}/root/.xinitrc"
  echo "exec feh --bg-fill /usr/local/share/backgrounds/ghostbsd/Lake_View.jpg &" >> "${release}/root/.xinitrc"
  echo "exec setup-station" >> "${release}/root/.xinitrc"
}

patch_etc_files

git_pc_sysinstall
git_gbi
git_install_station
git_setup_station

ghostbsd_setup_liveuser
ghostbsd_setup_autologin
lightdm_setup
setup_xinit
final_setup
