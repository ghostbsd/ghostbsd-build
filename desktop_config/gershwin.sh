#!/bin/sh

set -e -u

. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/setuser.sh"

loginwindow_setup()
{
  return 0
}

setup_xinit()
{
  chroot "${release}" su "${live_user}" -c "echo 'exec /System/Library/Scripts/Gershwin.sh' > /Local/Users/${live_user}/.xinitrc"
  echo "exec /System/Library/Scripts/Gershwin.sh" > "${release}/root/.xinitrc"
  echo "exec /System/Library/Scripts/Gershwin.sh" > "${release}/usr/share/skel/dot.xinitrc"
}

patch_etc_files
patch_loader_conf_d
community_setup_liveuser_gershwin
community_setup_autologin_gershwin
loginwindow_setup
setup_xinit
final_setup
