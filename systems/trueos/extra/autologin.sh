#!/bin/sh

set -e -u


setup_autologin()
{
  echo "# ${liveuser} user autologin" >> ${release}/etc/gettytab
  echo "${liveuser}:\\" >> ${release}/etc/gettytab
  echo ":al=${liveuser}:ht:np:sp#115200:" >> ${release}/etc/gettytab
  sed -i "" "/ttyv0/s/Pc/${liveuser}/g" ${release}/etc/ttys
  # echo "sh sysconfig.sh" >> ${release}/root/.login
  mkdir -p ${release}/usr/home${liveuser}/.config/fish
  echo 'exec sh ~/.login' >  ${release}/usr/home${liveuser}/.config/fish/config.fish
  echo "startx" >> ${release}/usr/home/${liveuser}/.login
}
