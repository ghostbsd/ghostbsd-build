#!/bin/sh
set -e -u

. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/gitpkg.sh"
. "${cwd}/common_config/setuser.sh"
. "${cwd}/common_config/splash-setup.sh"

lightdm_setup()
{
  sed -i '' "s@#greeter-session=example-gtk-gnome@greeter-session=slick-greeter@" "${release}/usr/local/etc/lightdm/lightdm.conf"
  sed -i '' "s@#user-session=default@user-session=gershwin@" "${release}/usr/local/etc/lightdm/lightdm.conf"
}

setup_xinit()
{
  chroot "${release}" su "${live_user}" -c "echo 'exec /usr/local/bin/gershwin-x11' > /Users/${live_user}/.xinitrc"
  echo "exec /usr/local/bin/gershwin-x11" > "${release}/root/.xinitrc"
  echo "exec /usr/local/bin/gershwin-x11" > "${release}/usr/share/skel/dot.xinitrc"
}

# Apply base system patches
patch_etc_files

# Set up user and autologin with interactive splash support (using Gershwin functions)
community_setup_liveuser_interactive_gershwin
community_setup_autologin_interactive_gershwin

# Configure desktop environment
lightdm_setup
setup_xinit

# Apply final setup
final_setup
