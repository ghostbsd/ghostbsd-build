#!/bin/sh

set -e -u


setup_autologin()
{
  echo "# ${liveuser} user autologin" >> ${release}/etc/gettytab
  echo "${liveuser}:\\" >> ${release}/etc/gettytab
  echo ":al=${liveuser}:ht:np:sp#115200:" >> ${release}/etc/gettytab
  sed -i "" "/ttyv0/s/Pc/${liveuser}/g" ${release}/etc/ttys
  mkdir -p ${release}/usr/home/${liveuser}/.config/fish
  if [ -f "${release}/usr/local/bin/xconfig" ] ; then
    printf 'if not test -f /tmp/.xstarted
  touch /tmp/.xstarted
  set tty (tty)
  if test $tty = \"/dev/ttyv0\"
    exec xconfig auto
  end
end
' > ${release}/usr/home/${liveuser}/.config/fish/config.fish
  chmod 765 ${release}/usr/home/${liveuser}/.config/fish/config.fish
  fi
}
