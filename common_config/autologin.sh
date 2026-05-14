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
  cat > "${release}/home/${live_user}/.zshrc" <<'EOF'
if [ "$(tty)" = "/dev/ttyv0" ]; then
  sudo xconfig auto
  sleep 1
  startx
  sleep 1
  startx
fi
EOF
  chmod 765 "${release}/home/${live_user}/.zshrc"

  # setup root
  printf "if [ \"\$(tty)\" = \"/dev/ttyv0\" ]; then
  startx
  logout
fi
" >> "${release}/root/.shrc"
  chmod 644 "${release}/root/.shrc"
}

community_setup_autologin()
{
  {
    echo "# ${live_user} user autologin"
    echo "${live_user}:\\"
    echo ":al=${live_user}:ht:np:sp#115200:"
  } >> "${release}/etc/gettytab"
  sed -i "" "/ttyv0/s/Pc/${live_user}/g" "${release}/etc/ttys"
  if [ -f "${release}/usr/local/bin/xconfig" ] ; then
    cat > "${release}/home/${live_user}/.zshrc" <<'EOF'
if [ ! -f /tmp/.xstarted ]; then
  touch /tmp/.xstarted
  if [ "$(tty)" = "/dev/ttyv0" ]; then
    sudo xconfig auto
    sleep 1
    startx
  fi
fi
EOF
    chmod 765 "${release}/home/${live_user}/.zshrc"
  fi
}

community_setup_autologin_gershwin()
{
  {
    echo "# ${live_user} user autologin"
    echo "${live_user}:\\"
    echo ":al=${live_user}:ht:np:sp#115200:"
  } >> "${release}/etc/gettytab"

  sed -i "" "/ttyv0/s/Pc/${live_user}/g" "${release}/etc/ttys"

  if [ -f "${release}/usr/local/bin/xconfig" ] ; then
    cat > "${release}/Local/Users/${live_user}/.zshrc" <<'EOF'
if [ ! -f /tmp/.xstarted ]; then
  touch /tmp/.xstarted
  sudo xconfig auto
  sleep 1
  startx
fi
EOF

    chmod 765 "${release}/Local/Users/${live_user}/.zshrc"
    chown 1100:wheel "${release}/Local/Users/${live_user}/.zshrc"
  fi
}
