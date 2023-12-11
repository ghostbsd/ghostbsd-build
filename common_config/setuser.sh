#!/bin/sh

set -e -u

set_user()
{
  chroot "${release}" pw usermod -s /usr/local/bin/fish -n root
  chroot "${release}" pw useradd "${liveuser}" \
  -c "GhostBSD Live User" -d "/home/${liveuser}" \
  -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
}

ghostbsd_setup_liveuser()
{
  set_user
  chroot "${release}" su "${liveuser}" -c "mkdir -p /home/${liveuser}/.config/gtk-3.0"
  chroot "${release}" su "${liveuser}" -c "echo '[Settings]' >> /home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-application-prefer-dark-theme = false' >> /home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-theme-name = Vimix' >> /home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-icon-theme-name = Vivacious-Colors-Dark' >> /home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-font-name = Droid Sans Bold 12' >> /home/${liveuser}/.config/gtk-3.0/settings.ini"
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
  chroot "${release}" su "${liveuser}" -c "mkdir -p /home/${liveuser}/Desktop"

  if [ -e "${release}/usr/local/share/applications/gbi.desktop" ] ; then
   chroot "${release}" su "${liveuser}" -c  "cp -af /usr/local/share/applications/gbi.desktop /home/${liveuser}/Desktop"
   chroot "${release}" su "${liveuser}" -c  "chmod +x /home/${liveuser}/Desktop/gbi.desktop"
   sed -i '' -e 's/NoDisplay=true/NoDisplay=false/g' "${release}/home/${liveuser}/Desktop/gbi.desktop"
  fi
}