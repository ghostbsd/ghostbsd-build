#!/bin/sh
#
# FreeBSD Plasma + SDDM live setup script
#

set -e -u

# Source common configuration scripts
. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/setuser.sh"

update_rcconf_dm() {
  rc_conf="${release}/etc/rc.conf"

  # Remove LightDM entries
  sed -i '' '/^lightdm_enable=.*/d' "${rc_conf}" 2>/dev/null || true

  # Remove stale SDDM entries
  sed -i '' '/^sddm_enable=.*/d' "${rc_conf}" 2>/dev/null || true

  # Enable SDDM
  echo 'sddm_enable="YES"' >> "${rc_conf}"
}

localtime() {
  # Detect hardware clock timezone from BIOS (assumes BIOS is in UTC)
  # FreeBSD convention: set timezone in /etc/localtime
  # Copy UTC by default; adjust later if needed
  tz_target="${release}/etc/localtime"

  # Remove existing symlink/file
  rm -f "${tz_target}"

  # Link BIOS UTC to system UTC
  ln -s /usr/share/zoneinfo/UTC "${tz_target}"

  # Ensure rc.conf knows hwclock type
  rc_conf="${release}/etc/rc.conf"
  sed -i '' '/^ntpd_enable=.*/d' "${rc_conf}" 2>/dev/null || true
  sed -i '' '/^ntpd_sync_on_start=.*/d' "${rc_conf}" 2>/dev/null || true
  sed -i '' '/^local_unbound_enable=.*/d' "${rc_conf}" 2>/dev/null || true

  echo 'ntpd_enable="YES"' >> "${rc_conf}"
  echo 'ntpd_sync_on_start="YES"' >> "${rc_conf}"
}

sddm_setup() {
  sddm_conf="${release}/etc/sddm.conf"

  if [ ! -f "${sddm_conf}" ]; then
    cat <<EOF > "${sddm_conf}"
[Autologin]
User=${live_user}
Session=plasma

[Theme]
Current=breeze

[General]
Numlock=on
EOF
  else
    grep -q "^\[Autologin\]" "${sddm_conf}" || echo "[Autologin]" >> "${sddm_conf}"
    sed -i '' "s@^User=.*@User=${live_user}@" "${sddm_conf}" || echo "User=${live_user}" >> "${sddm_conf}"
    sed -i '' "s@^Session=.*@Session=plasma@" "${sddm_conf}" || echo "Session=plasma" >> "${sddm_conf}"

    grep -q "^\[Theme\]" "${sddm_conf}" || echo "[Theme]" >> "${sddm_conf}"
    sed -i '' "s@^Current=.*@Current=breeze@" "${sddm_conf}" || echo "Current=breeze" >> "${sddm_conf}"

    grep -q "^\[General\]" "${sddm_conf}" || echo "[General]" >> "${sddm_conf}"
    sed -i '' "s@^Numlock=.*@Numlock=on@" "${sddm_conf}" || echo "Numlock=on" >> "${sddm_conf}"
  fi
}

plasma_settings() {
  sysctl_conf="${release}/etc/sysctl.conf"

  sed -i '' '/^net.local.stream.recvspace/d' "${sysctl_conf}" 2>/dev/null || true
  sed -i '' '/^net.local.stream.sendspace/d' "${sysctl_conf}" 2>/dev/null || true

  echo 'net.local.stream.recvspace=65536' >> "${sysctl_conf}"
  echo 'net.local.stream.sendspace=65536' >> "${sysctl_conf}"

}
setup_xinit() {
  chroot "${release}" su "${live_user}" -c "
    mkdir -p /home/${live_user}/.config
    kwriteconfig5 --file /home/${live_user}/.config/kscreenlockerrc --group Daemon --key Autolock false
    kwriteconfig5 --file /home/${live_user}/.config/kscreenlockerrc --group Daemon --key LockOnResume false
    echo 'exec ck-launch-session startplasma-x11' >> /home/${live_user}/.xinitrc
  "
  echo "exec ck-launch-session startplasma-x11" > "${release}/root/.xinitrc"
  echo "exec ck-launch-session startplasma-x11" > "${release}/usr/share/skel/dot.xinitrc"
}

# Execute setup routines
patch_etc_files
community_setup_liveuser
community_setup_autologin
update_rcconf_dm
localtime
sddm_setup
plasma_settings
setup_xinit
final_setup
