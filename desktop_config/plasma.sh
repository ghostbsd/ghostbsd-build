#!/bin/sh

set -e -u

# Source common configuration scripts
. "${cwd}/common_config/autologin.sh"
. "${cwd}/common_config/base-setting.sh"
. "${cwd}/common_config/finalize.sh"
. "${cwd}/common_config/setuser.sh"

sddm_setup() {
  # Path to SDDM config
  sddm_conf="${release}/etc/sddm.conf"

  # Create or update SDDM configuration
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
    # Ensure required sections exist and update keys
    grep -q "^\[Autologin\]" "${sddm_conf}" || echo "[Autologin]" >> "${sddm_conf}"
    sed -i '' "s@^User=.*@User=${live_user}@" "${sddm_conf}" || echo "User=${live_user}" >> "${sddm_conf}"
    sed -i '' "s@^Session=.*@Session=plasma@" "${sddm_conf}" || echo "Session=plasma" >> "${sddm_conf}"

    grep -q "^\[Theme\]" "${sddm_conf}" || echo "[Theme]" >> "${sddm_conf}"
    sed -i '' "s@^Current=.*@Current=breeze@" "${sddm_conf}" || echo "Current=breeze" >> "${sddm_conf}"

    grep -q "^\[General\]" "${sddm_conf}" || echo "[General]" >> "${sddm_conf}"
    sed -i '' "s@^Numlock=.*@Numlock=on@" "${sddm_conf}" || echo "Numlock=on" >> "${sddm_conf}"
  fi
}

setup_xinit() {
  # Disable screen locking in KDE Plasma for live_user
  chroot "${release}" su "${live_user}" -c "
    mkdir -p /home/${live_user}/.config
    kwriteconfig5 --file /home/${live_user}/.config/kscreenlockerrc --group Daemon --key Autolock false
    kwriteconfig5 --file /home/${live_user}/.config/kscreenlockerrc --group Daemon --key LockOnResume false
    echo 'exec ck-launch-session startplasma-x11' >> /home/${live_user}/.xinitrc
  "

  # Set the same .xinitrc for root and skel
  echo "exec ck-launch-session startplasma-x11" > "${release}/root/.xinitrc"
  echo "exec ck-launch-session startplasma-x11" > "${release}/usr/share/skel/dot.xinitrc"
}

# Execute setup routines
patch_etc_files
patch_loader_conf_d
community_setup_liveuser
community_setup_autologin
sddm_setup
setup_xinit
final_setup
