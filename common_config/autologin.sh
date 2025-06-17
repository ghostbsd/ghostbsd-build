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

community_setup_autologin_gershwin()
{
  {
    echo "# ${live_user} user autologin"
    echo "${live_user}:\\"
    echo ":al=${live_user}:ht:np:sp#115200:"
  } >> "${release}/etc/gettytab"

  sed -i "" "/ttyv0/s/Pc/${live_user}/g" "${release}/etc/ttys"

  mkdir -p "${release}/home/${live_user}/.config/fish"

  if [ -f "${release}/usr/local/bin/xconfig" ] ; then
    cat > "${release}/home/${live_user}/.config/fish/config.fish" <<'EOF'
function gnustep_env
  /bin/sh -c '. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh; env' \
  | while read -l line
    set -l parts (string split -m1 "=" $line)
    set -l var $parts[1]
    set -l val $parts[2]
    if test (count $parts) -eq 2
      switch $var
        case PWD SHLVL _
          # skip read-only vars
        case '*'
          set -gx $var $val
      end
    end
  end
end

gnustep_env

if not test -f /tmp/.xstarted
  touch /tmp/.xstarted
  set tty (tty)
  if test \$tty = "/dev/ttyv0"
    sudo xconfig auto
    sleep 1
    echo "X configuration completed"
    sleep 1
    sudo rm -rf /xdrivers
    sleep 1
    startx
  end
end
EOF

    chmod 765 "${release}/home/${live_user}/.config/fish/config.fish"
  fi
}
