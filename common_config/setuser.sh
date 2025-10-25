#!/bin/sh

set -e -u

set_user()
{
  chroot "${release}" pw useradd "${live_user}" -u 1100 \
  -c "GhostBSD Live User" -d "/home/${live_user}" \
  -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
}

set_user_gershwin()
{
  chroot "${release}" pw useradd "${live_user}" -u 1100 \
  -c "GhostBSD Live User" -d "/Users/${live_user}" \
  -g wheel -G operator -m -s /usr/local/bin/zsh -k /usr/share/skel -w none
}

ghostbsd_setup_liveuser()
{
  set_user
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/.config/gtk-3.0"
  chroot "${release}" su "${live_user}" -c "echo '[Settings]' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-application-prefer-dark-theme = false' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-theme-name = Vimix' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-icon-theme-name = Vivacious-Colors-Dark' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-font-name = Droid Sans Bold 12' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  mkdir -p "${release}/root/.config/gtk-3.0"
  {
    echo '[Settings]'
    echo 'gtk-application-prefer-dark-theme = false'
    echo 'gtk-theme-name = Vimix'
    echo 'gtk-icon-theme-name = Vivacious-Colors-Dark'
    echo 'gtk-font-name = Droid Sans Bold 12'
  } > "${release}/root/.config/gtk-3.0/settings.ini"
}

community_setup_liveuser()
{
  set_user
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/Desktop"

  if [ -e "${release}/usr/local/share/applications/gbi.desktop" ] ; then
   chroot "${release}" su "${live_user}" -c  "cp -af /usr/local/share/applications/gbi.desktop /home/${live_user}/Desktop"
   chroot "${release}" su "${live_user}" -c  "chmod +x /home/${live_user}/Desktop/gbi.desktop"
   sed -i '' -e 's/NoDisplay=true/NoDisplay=false/g' "${release}/home/${live_user}/Desktop/gbi.desktop"
   # Trust desktop file for XFCE 4.18+ using checksum metadata
   if [ "${desktop}" = "xfce" ] ; then
     # shellcheck disable=SC2016
     chroot "${release}" su - "${live_user}" -c '
       dbus-run-session -- sh -c "
         /usr/local/libexec/gvfsd >/dev/null 2>&1 &
         /usr/local/libexec/gvfsd-metadata >/dev/null 2>&1 &
         sleep 1
         f=\$HOME/Desktop/gbi.desktop
         sum=\$(sha256 -q \"\$f\")
         gio set -t string \"\$f\" metadata::xfce-exe-checksum \"\$sum\"
       "
     '
   fi
  fi
}

community_setup_liveuser_gershwin()
{
  set_user_gershwin
  chroot "${release}" su - "${live_user}" -c "xdg-user-dirs-update"
  chroot "${release}" su - "${live_user}" -c "ln -sf /System/Applications/Installer.app \"/Users/${live_user}/Desktop/Installer.app\""
}