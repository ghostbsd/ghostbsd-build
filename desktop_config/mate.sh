#!/bin/sh

set -e -u

. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/setuser.sh"

lightdm_setup()
{
  lightdm_conf="${release}/usr/local/etc/lightdm/lightdm.conf"
  sed -i '' "s@#greeter-session=example-gtk-gnome@greeter-session=slick-greeter@" "${lightdm_conf}"
  sed -i '' "s@#user-session=default@user-session=mate@" "${lightdm_conf}"
  # Autologin the live user so choosing "Try" in install-station lands straight
  # in the desktop. This replaces the gettytab/ttys autologin the other desktops
  # still use. pc-sysinstall strips both keys from the installed system.
  sed -i '' "s@^#autologin-user=\$@autologin-user=${live_user}@" "${lightdm_conf}"
  sed -i '' "s@^#autologin-session=\$@autologin-session=mate@" "${lightdm_conf}"
  chroot "${release}" sysrc lightdm_enable="YES"
}

rc_conf_setup()
{
  # Per-service files rather than /etc/rc.conf, so pc-sysinstall can drop the
  # installer's entry from the installed system with a single rm.
  sysrc -f "${release}/etc/rc.conf.d/xconfig" xconfig_enable="YES"
  sysrc -f "${release}/etc/rc.conf.d/install_station" install_station_enable="YES"
}

live_gsettings()
{
  # Keep the live session from locking. The live user has no password, and
  # lightdm never reads .xinitrc, so these have to be schema defaults rather
  # than gsettings calls racing session startup. pc-sysinstall removes this
  # file and recompiles the schemas on the installed system.
  cat > "${release}/usr/local/share/glib-2.0/schemas/99_ghostbsd_live.gschema.override" <<'EOF'
[org.mate.screensaver]
lock-enabled=false
idle-activation-enabled=false

[org.mate.lockdown]
disable-lock-screen=true
disable-user-switching=true
EOF
  chroot "${release}" glib-compile-schemas /usr/local/share/glib-2.0/schemas
}

setup_xinit()
{
  echo "exec ck-launch-session mate-session" > "${release}/root/.xinitrc"
  echo "exec ck-launch-session mate-session" > "${release}/usr/share/skel/dot.xinitrc"
}

patch_etc_files
patch_loader_conf_d
community_setup_liveuser
lightdm_setup
live_gsettings
rc_conf_setup
setup_xinit
final_setup
