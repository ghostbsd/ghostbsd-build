#!/bin/sh

set -e -u

setup_liveuser()
{
  #${release} su ${liveuser} -c "mkdir -p /usr/home/${liveuser}/Desktop"

  #if [ -e ${release}/usr/local/share/applications/gbi.desktop ] ; then
  #  chroot ${release} su ${liveuser} -c  "cp -af /usr/local/share/applications/gbi.desktop /usr/home/${liveuser}/Desktop"
  #  chroot ${release} su ${liveuser} -c  "chmod +x /usr/home/${liveuser}/Desktop/gbi.desktop"
  #  sed -i '' -e 's/NoDisplay=true/NoDisplay=false/g' ${release}/usr/home/${liveuser}/Desktop/gbi.desktop
  #fi

  chroot "${release}" su "${liveuser}" -c "mkdir -p /usr/home/${liveuser}/.config/gtk-3.0"
  chroot "${release}" su "${liveuser}" -c "echo '[Settings]' >> /usr/home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-application-prefer-dark-theme = false' >> /usr/home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-theme-name = Vimix' >> /usr/home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-icon-theme-name = Vivacious-Colors-Dark' >> /usr/home/${liveuser}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${liveuser}" -c "echo 'gtk-font-name = Droid Sans Bold 12' >> /usr/home/${liveuser}/.config/gtk-3.0/settings.ini"

  mkdir -p "${release}/root/.config/gtk-3.0"
  {
    echo '[Settings]'
    echo 'gtk-application-prefer-dark-theme = false'
    echo 'gtk-theme-name = Vimix'
    echo 'gtk-icon-theme-name = Vivacious-Colors-Dark'
    echo 'gtk-font-name = Droid Sans Bold 12'
  } > "${release}/root/.config/gtk-3.0/settings.ini"
}
