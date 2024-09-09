#!/bin/sh

set -e -u

set_user()
{
  chroot "${release}" pw usermod -s /usr/local/bin/fish -n root
  chroot "${release}" pw useradd "${live_user}" \
  -c "GhostBSD Live User" -d "/home/${live_user}" \
  -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
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
  fi
}
