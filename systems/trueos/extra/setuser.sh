#!/bin/sh

set -e -u

setup_liveuser()
{
  chroot ${release} su ${liveuser} -c "mkdir -p /usr/home/${liveuser}/Desktop"
  chroot ${release} su ${liveuser} -c "/usr/local/bin/xdg-user-dirs-update"

  if [ -e ${release}/usr/local/share/applications/ghostbsd-irc.desktop ] ; then
    chroot ${release} su ${liveuser} -c  "cp -af /usr/local/share/applications/ghostbsd-irc.desktop /usr/home/${liveuser}/Desktop"
    chroot ${release} su ${liveuser} -c  "chmod +x /usr/home/${liveuser}/Desktop/ghostbsd-irc.desktop"
  fi

  if [ -e ${release}/usr/local/share/applications/gbi.desktop ] ; then
    chroot ${release} su ${liveuser} -c  "cp -af /usr/local/share/applications/gbi.desktop /usr/home/${liveuser}/Desktop"
    chroot ${release} su ${liveuser} -c  "chmod +x /usr/home/${liveuser}/Desktop/gbi.desktop"
  fi
}
