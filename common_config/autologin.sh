#!/bin/sh

set -e -u

ghostbsd_setup_autologin()
{
  {
    echo "# ${live_user} user autologin"
    echo "${live_user}:\\"
    echo ":al=${live_user}:ht:np:sp#115200:"
  } >> "${release}/etc/gettytab"
  sed -i "" "/ttyv0/s/Pc/${live_user}/g" "${release}/etc/ttys"
  mkdir -p "${release}/home/${live_user}/.config/fish"
  printf "set tty (tty)
  if test \$tty = \"/dev/ttyv0\"
    sudo xconfig auto
    sleep 1
    sudo rm -rf /xdrivers
    sleep 1
    startx
    sleep 1
    startx
  end
" > "${release}/home/${live_user}/.config/fish/config.fish"
  chmod 765 "${release}/home/${live_user}/.config/fish/config.fish"

  # setup root
  mkdir -p "${release}/root/.config/fish"
  printf "set tty (tty)
  if test \$tty = \"/dev/ttyv0\"
    exec startx
  end
" > "${release}/root/.config/fish/config.fish"
  chmod 765 "${release}/root/.config/fish/config.fish"
}

community_setup_autologin()
{
  {
    echo "# ${live_user} user autologin"
    echo "${live_user}:\\"
    echo ":al=${live_user}:ht:np:sp#115200:"
  } >> "${release}/etc/gettytab"
  sed -i "" "/ttyv0/s/Pc/${live_user}/g" "${release}/etc/ttys"
  mkdir -p "${release}/home/${live_user}/.config/fish"
  if [ -f "${release}/usr/local/bin/xconfig" ] ; then
    printf "if not test -f /tmp/.xstarted
  touch /tmp/.xstarted
  set tty (tty)
  if test \$tty = \"/dev/ttyv0\"
    sudo xconfig auto
    sleep 1
    echo \"X configuation completed\"
    sleep 1
    sudo rm -rf /xdrivers
    sleep 1
    startx
  end
end
" > "${release}/home/${live_user}/.config/fish/config.fish"
  chmod 765 "${release}/home/${live_user}/.config/fish/config.fish"
  fi
}
