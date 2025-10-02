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

  if [ -f "${release}/usr/local/bin/xconfig" ] ; then
    cat > "${release}/Users/${live_user}/.zshrc" <<'EOF'
if [ ! -f /tmp/.xstarted ]; then
  touch /tmp/.xstarted
  sudo xconfig auto
  sleep 1
  echo "X configuration completed"
  sleep 1
  sudo rm -rf /xdrivers
  sleep 1
  startx
fi
EOF

    chmod 765 "${release}/Users/${live_user}/.zshrc"
    chown 1100:wheel "${release}/Users/${live_user}/.zshrc"
  fi
}

# FIXED FUNCTIONS FOR INTERACTIVE SPLASH SCREEN WITH TTY-SAFE EXTENDED BOOT

community_setup_autologin_interactive()
{
  {
    echo "# ${live_user} user autologin"
    echo "${live_user}:\\"
    echo ":al=${live_user}:ht:np:sp#115200:"
  } >> "${release}/etc/gettytab"
  sed -i "" "/ttyv0/s/Pc/${live_user}/g" "${release}/etc/ttys"
  
  mkdir -p "${release}/home/${live_user}/.config/fish"
  
  cat > "${release}/home/${live_user}/.config/fish/config.fish" << 'EOF'
if not test -f /tmp/.xstarted
    touch /tmp/.xstarted
    set tty (tty)
    if test $tty = "/dev/ttyv0"
        # Start extended boot splash screen (direct call, no backgrounding)
        if test -f /usr/local/bin/ghostbsd-extended-boot
            /usr/local/bin/ghostbsd-extended-boot
        end
        
        echo "Configuring display drivers..."
        if test -f /usr/local/bin/xconfig
            if test -f /tmp/.verbose_boot
                sudo xconfig auto
            else
                sudo xconfig auto >/dev/null 2>&1
            end
            sleep 1
            echo "X configuration completed"
            sleep 1
            sudo rm -rf /xdrivers >/dev/null 2>&1
            sleep 1
        end
        
        echo "Starting desktop environment..."
        if test -f /tmp/.verbose_boot
            startx
        else
            startx >/dev/null 2>&1
        end
    end
end
EOF
  chmod 765 "${release}/home/${live_user}/.config/fish/config.fish"
}

community_setup_autologin_interactive_gershwin()
{
  {
    echo "# ${live_user} user autologin"
    echo "${live_user}:\\"
    echo ":al=${live_user}:ht:np:sp#115200:"
  } >> "${release}/etc/gettytab"

  sed -i "" "/ttyv0/s/Pc/${live_user}/g" "${release}/etc/ttys"

  if [ -f "${release}/usr/local/bin/xconfig" ] ; then
    cat > "${release}/Users/${live_user}/.zshrc" << 'EOF'
if [ ! -f /tmp/.xstarted ]; then
  touch /tmp/.xstarted
  
  # Check if extended boot script exists and run it directly (no backgrounding)
  if [ -f /usr/local/bin/ghostbsd-extended-boot ]; then
    /usr/local/bin/ghostbsd-extended-boot
  else
    echo "GhostBSD Live System Loading..."
    sleep 2
  fi
  
  echo "Configuring display drivers..."
  if [ -f /tmp/.verbose_boot ]; then
    sudo xconfig auto
  else
    sudo xconfig auto >/dev/null 2>&1
  fi
  sleep 1
  echo "X configuration completed"
  sleep 1
  sudo rm -rf /xdrivers >/dev/null 2>&1
  sleep 1
  
  echo "Starting desktop environment..."
  if [ -f /tmp/.verbose_boot ]; then
    startx
  else
    startx >/dev/null 2>&1
  fi
fi
EOF

    chmod 765 "${release}/Users/${live_user}/.zshrc"
    chown 1100:wheel "${release}/Users/${live_user}/.zshrc"
  fi
}

# Interactive autologin with extended boot splash for GhostBSD edition - FIXED
ghostbsd_setup_autologin_interactive()
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
    # Start extended boot splash screen (direct call, no backgrounding)
    if test -f /usr/local/bin/ghostbsd-extended-boot
      /usr/local/bin/ghostbsd-extended-boot
    end
    
    echo \"Configuring display drivers...\"
    if test -f /tmp/.verbose_boot
      sudo xconfig auto
    else
      sudo xconfig auto >/dev/null 2>&1
    end
    sleep 1
    sudo rm -rf /xdrivers >/dev/null 2>&1
    sleep 1
    
    echo \"Starting desktop environment...\"
    if test -f /tmp/.verbose_boot
      startx
    else
      startx >/dev/null 2>&1
    end
    sleep 1
    if test -f /tmp/.verbose_boot
      startx
    else
      startx >/dev/null 2>&1
    end
  end
" > "${release}/home/${live_user}/.config/fish/config.fish"
  chmod 765 "${release}/home/${live_user}/.config/fish/config.fish"

  # setup root with extended boot splash support - FIXED
  mkdir -p "${release}/root/.config/fish"
  printf "set tty (tty)
  if test \$tty = \"/dev/ttyv0\"
    if test -f /tmp/.verbose_boot
      exec startx
    else
      if test -f /usr/local/bin/ghostbsd-ascii-logo
        /usr/local/bin/ghostbsd-ascii-logo
      end
      exec startx >/dev/null 2>&1
    end
  end
" > "${release}/root/.config/fish/config.fish"
  chmod 765 "${release}/root/.config/fish/config.fish"
}
