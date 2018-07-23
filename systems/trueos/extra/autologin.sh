#!/bin/sh

set -e -u


setup_autologin()
{
  echo "# liveuser user autologin" >> ${release}/etc/gettytab
  echo "liveuser:\\" >> ${release}/etc/gettytab
  echo ":al=liveuser:ht:np:sp#115200:" >> ${release}/etc/gettytab

  sed -i "" "/ttyv0/s/Pc/liveuser/g" ${release}/etc/ttys
  # echo "sh sysconfig.sh" >> ${release}/root/.login
  echo "startx" >> ${release}/home/liveuser/.login
  # echo 'if ($tty == ttyv0) then' >> ${release}/home/liveuser/.cshrc
  # echo 'if ($tty == ttyv0) then' >> ${release}/home/liveuser/.shrc
  # echo "  sudo netcardmgr" >> ${release}/home/liveuser/.cshrc
  # echo "  startx" >> ${release}/home/liveuser/.cshrc
  # echo "  startx" >> ${release}/home/liveuser/.shrc
  # echo "endif" >> ${release}/home/liveuser/.cshrc
  # echo "endif" >> ${release}/home/liveuser/.shrc
}
