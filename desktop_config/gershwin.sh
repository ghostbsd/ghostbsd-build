#!/bin/sh

set -e -u

. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/setuser.sh"

setup_applications()
{
  echo "Building Gershwin applications in chroot..."
  
  # Ensure network is available in chroot
  cp /etc/resolv.conf "${release}/etc/resolv.conf"
  
  # Run everything INSIDE the chroot
  chroot "${release}" /bin/sh << 'EOF'
. /System/Library/Makefiles/GNUstep.sh
cd /tmp
git clone --depth 1 https://github.com/gershwin-desktop/gershwin-universe-apps
cd /tmp/gershwin-universe-apps/Dictionary
gmake && gmake install
cd /tmp/gershwin-universe-apps/TextEdit
gmake && gmake install
cd /tmp/gershwin-universe-apps/Terminal
gmake && gmake install
rm -rf /tmp/gershwin-universe-apps
EOF
  
  # Clean up
  rm -f "${release}/etc/resolv.conf"
}

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

patch_etc_files
community_setup_liveuser_gershwin
community_setup_autologin_gershwin
setup_applications
lightdm_setup
setup_xinit
final_setup
