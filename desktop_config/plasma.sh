#!/bin/sh

set -e -u

# Source common configuration scripts
. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/setuser.sh"

update_rcconf_dm() {
  rc_conf="${release}/etc/rc.conf"
  echo 'ntpdate_hosts="asia.pool.ntp.org"' >> "${rc_conf}"
}

lightdm_setup() {
  lightdm_conf="${release}/usr/local/etc/lightdm/lightdm.conf"
  sed -i '' "s@#greeter-session=.*@greeter-session=slick-greeter@" "${lightdm_conf}"
  sed -i '' "s@#user-session=default@user-session=plasma@" "${lightdm_conf}"
}

# ADD: Enable KDE Greeter
lightdm_kde_greeter_conf() {
  mkdir -p "${release}/usr/local/etc/lightdm/lightdm.conf.d"
  cat <<EOF > "${release}/usr/local/etc/lightdm/lightdm.conf.d/50-myconfig.conf"
[Seat:*]
greeter-session=lightdm-kde-greeter
EOF
}

set_localtime_from_bios() {
  tz_target="${release}/etc/localtime"

  rm -f "${tz_target}"
  ln -s /usr/share/zoneinfo/UTC "${tz_target}"

  rc_conf="${release}/etc/rc.conf"
  sed -i '' '/^ntpd_enable=.*/d' "${rc_conf}" 2>/dev/null || true
  sed -i '' '/^ntpd_sync_on_start=.*/d' "${rc_conf}" 2>/dev/null || true
  sed -i '' '/^local_unbound_enable=.*/d' "${rc_conf}" 2>/dev/null || true

  {
    echo 'ntpd_enable="YES"'
    echo 'ntpd_sync_on_start="YES"'
    echo 'ntpdate_enable="YES"'
  } >> "${rc_conf}"
}

plasma_settings() {
  sysctl_conf="${release}/etc/sysctl.conf"

  sed -i '' '/^net.local.stream.recvspace/d' "${sysctl_conf}" 2>/dev/null || true
  sed -i '' '/^net.local.stream.sendspace/d' "${sysctl_conf}" 2>/dev/null || true

  {
    echo 'net.local.stream.recvspace=65536'
    echo 'net.local.stream.sendspace=65536'
    echo 'vfs.usermount=1'
  } >> "${sysctl_conf}"
}

setup_xinit() {
  chroot "${release}" su "${live_user}" -c "
    mkdir -p /home/${live_user}/.config

    # Disable lock screen
    kwriteconfig5 --file /home/${live_user}/.config/kscreenlockerrc --group Daemon --key Autolock false
    kwriteconfig5 --file /home/${live_user}/.config/kscreenlockerrc --group Daemon --key LockOnResume false

    # Add keyboard config
    grep -qxF 'setxkbmap us' /home/${live_user}/.xinitrc || echo 'setxkbmap us' >> /home/${live_user}/.xinitrc
    grep -qxF 'setxkbmap -option ctrl:swapcaps' /home/${live_user}/.xinitrc || echo 'setxkbmap -option ctrl:swapcaps' >> /home/${live_user}/.xinitrc

    # Plasma session
    grep -qxF 'exec dbus-launch --exit-with-session ck-launch-session startplasma-wayland 2> .error.log' /home/${live_user}/.xinitrc \
    || echo 'exec dbus-launch --exit-with-session ck-launch-session startplasma-wayland 2> .error.log' >> /home/${live_user}/.xinitrc
  "

  echo "setxkbmap us" > "${release}/root/.xinitrc"
  echo "setxkbmap -option ctrl:swapcaps" >> "${release}/root/.xinitrc"
  echo "exec dbus-launch --exit-with-session ck-launch-session startplasma-wayland 2> .error.log" >> "${release}/root/.xinitrc"

  echo "setxkbmap us" > "${release}/usr/share/skel/.xinitrc"
  echo "setxkbmap -option ctrl:swapcaps" >> "${release}/usr/share/skel/.xinitrc"
  echo "exec dbus-launch --exit-with-session ck-launch-session startplasma-wayland 2> .error.log" >> "${release}/usr/share/skel/.xinitrc"

}

configure_devfs() {
  devfs_rules="${release}/etc/devfs.rules"
  rc_conf="${release}/etc/rc.conf"

  echo '[localrules=10]' >> "${devfs_rules}"
  echo "add path 'da*' mode 0666 group operator" >> "${devfs_rules}"
  echo 'devfs_system_ruleset="localrules"' >> "${rc_conf}"
}

setup_polkit_rules() {
  polkit_rules_dir="${release}/usr/local/etc/polkit-1/rules.d"
  polkit_rules_file="${polkit_rules_dir}/10-mount.rules"

  mkdir -p "${polkit_rules_dir}"

  cat <<EOF > "${polkit_rules_file}"
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
}

# Execute setup routines
patch_etc_files
patch_loader_conf_d
community_setup_liveuser
community_setup_autologin
configure_devfs
update_rcconf_dm
lightdm_setup
lightdm_kde_greeter_conf
set_localtime_from_bios
plasma_settings
setup_polkit_rules
setup_xinit
final_setup
