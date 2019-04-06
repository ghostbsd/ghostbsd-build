#!/bin/sh

set -e -u


setup_autologin()
{
  echo "# ${liveuser} user autologin" >> ${release}/etc/gettytab
  echo "${liveuser}:\\" >> ${release}/etc/gettytab
  echo ":al=${liveuser}:ht:np:sp#115200:" >> ${release}/etc/gettytab
  sed -i "" "/ttyv0/s/Pc/${liveuser}/g" ${release}/etc/ttys
  mkdir -p ${release}/usr/home/${liveuser}/.config/fish
  cp ${cwd}/extra/autologin/config.fish ${release}/usr/home/${liveuser}/.config/fish/config.fish
  chmod 765 ${release}/usr/home/${liveuser}/.config/fish/config.fish
}
