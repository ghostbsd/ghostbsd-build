#!/bin/sh

set -e -u

. "${cwd}/common_config/live-setting.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/setuser.sh"

lightdm_setup()
{
  sed -i '' "s@#greeter-session=example-gtk-gnome@greeter-session=slick-greeter@" "${release}/usr/local/etc/lightdm/lightdm.conf"
  sed -i '' "s@#user-session=default@user-session=mate@" "${release}/usr/local/etc/lightdm/lightdm.conf"
}

setup_xinit()
{
  chroot "${release}" su "${liveuser}" -c "echo 'gsettings set org.mate.SettingsDaemon.plugins.housekeeping active true &' > /usr/home/${liveuser}/.xinitrc"
  chroot "${release}" su "${liveuser}" -c "echo 'gsettings set org.mate.screensaver lock-enabled false &' >> /usr/home/${liveuser}/.xinitrc"
  chroot "${release}" su "${liveuser}" -c "echo 'gsettings set org.mate.lockdown disable-lock-screen true &' >> /usr/home/${liveuser}/.xinitrc"
  chroot "${release}" su "${liveuser}" -c "echo 'gsettings set org.mate.lockdown disable-user-switching true &' >> /usr/home/${liveuser}/.xinitrc"
  chroot "${release}" su "${liveuser}" -c "echo 'exec ck-launch-session mate-session' >> /usr/home/${liveuser}/.xinitrc"
  echo "exec ck-launch-session mate-session" > "${release}/root/.xinitrc"
  echo "exec ck-launch-session mate-session" > "${release}/usr/share/skel/dot.xinitrc"
}

set_live_system
patch_etc_files
community_setup_liveuser
community_setup_autologin
lightdm_setup
setup_xinit
final_setup