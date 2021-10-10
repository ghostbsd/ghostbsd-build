#!/bin/sh

set -e -u


setup_autologin()
{
  echo "# ${liveuser} user autologin" >> ${release}/etc/gettytab
  echo "${liveuser}:\\" >> ${release}/etc/gettytab
  echo ":al=${liveuser}:ht:np:sp#115200:" >> ${release}/etc/gettytab
  sed -i "" "/ttyv0/s/Pc/${liveuser}/g" ${release}/etc/ttys
  mkdir -p ${release}/usr/home/${liveuser}/.config/fish
  printf 'set tty (tty)
  if test $tty = \"/dev/ttyv0\"
    startx
    sleep 1
    sudo xconfig auto
    sleep 1
    startx
  end
' > ${release}/usr/home/${liveuser}/.config/fish/config.fish
  chmod 765 ${release}/usr/home/${liveuser}/.config/fish/config.fish

  # setup root
  mkdir -p ${release}/root/.config/fish
  printf 'set tty (tty)
  if test $tty = \"/dev/ttyv0\"
    exec startx
  end
' > ${release}/root/.config/fish/config.fish
  chmod 765 ${release}/root/.config/fish/config.fish
}
