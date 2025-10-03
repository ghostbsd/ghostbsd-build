#!/bin/sh

set -e -u

set_user()
{
  chroot "${release}" pw useradd "${live_user}" -u 1100 \
  -c "GhostBSD Live User" -d "/home/${live_user}" \
  -g wheel -G operator -m -s /usr/local/bin/fish -k /usr/share/skel -w none
}

set_user_gershwin()
{
  chroot "${release}" pw useradd "${live_user}" -u 1100 \
  -c "GhostBSD Live User" -d "/Users/${live_user}" \
  -g wheel -G operator -m -s /usr/local/bin/zsh -k /usr/share/skel -w none
}

ghostbsd_setup_liveuser()
{
  set_user
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/.config/gtk-3.0"
  chroot "${release}" su "${live_user}" -c "echo '[Settings]' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-application-prefer-dark-theme = false' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-theme-name = Vimix' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-icon-theme-name = Vivacious-Colors-Dark' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-font-name = Droid Sans Bold 12' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  mkdir -p "${release}/root/.config/gtk-3.0"
  {
    echo '[Settings]'
    echo 'gtk-application-prefer-dark-theme = false'
    echo 'gtk-theme-name = Vimix'
    echo 'gtk-icon-theme-name = Vivacious-Colors-Dark'
    echo 'gtk-font-name = Droid Sans Bold 12'
  } > "${release}/root/.config/gtk-3.0/settings.ini"
}

community_setup_liveuser()
{
  set_user
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/Desktop"

  if [ -e "${release}/usr/local/share/applications/gbi.desktop" ] ; then
   chroot "${release}" su "${live_user}" -c  "cp -af /usr/local/share/applications/gbi.desktop /home/${live_user}/Desktop"
   chroot "${release}" su "${live_user}" -c  "chmod +x /home/${live_user}/Desktop/gbi.desktop"
   sed -i '' -e 's/NoDisplay=true/NoDisplay=false/g' "${release}/home/${live_user}/Desktop/gbi.desktop"
   # Trust desktop file for XFCE 4.18+ using checksum metadata
   if [ "${desktop}" = "xfce" ] ; then
     # shellcheck disable=SC2016
     chroot "${release}" su - "${live_user}" -c '
       dbus-run-session -- sh -c "
         /usr/local/libexec/gvfsd >/dev/null 2>&1 &
         /usr/local/libexec/gvfsd-metadata >/dev/null 2>&1 &
         sleep 1
         f=\$HOME/Desktop/gbi.desktop
         sum=\$(sha256 -q \"\$f\")
         gio set -t string \"\$f\" metadata::xfce-exe-checksum \"\$sum\"
       "
     '
   fi
  fi
}

community_setup_liveuser_gershwin()
{
  set_user_gershwin
  chroot "${release}" su - "${live_user}" -c "xdg-user-dirs-update"
  chroot "${release}" su - "${live_user}" -c "ln -sf /System/Applications/Installer.app \"/Users/${live_user}/Desktop/Installer.app\""
}

# NEW FUNCTIONS FOR INTERACTIVE SPLASH SCREEN SUPPORT

ghostbsd_setup_liveuser_interactive()
{
  # Set up user first
  set_user
  
  # Configure GTK settings
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/.config/gtk-3.0"
  chroot "${release}" su "${live_user}" -c "echo '[Settings]' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-application-prefer-dark-theme = false' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-theme-name = Vimix' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-icon-theme-name = Vivacious-Colors-Dark' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  chroot "${release}" su "${live_user}" -c "echo 'gtk-font-name = Droid Sans Bold 12' >> /home/${live_user}/.config/gtk-3.0/settings.ini"
  
  # Configure root GTK settings
  mkdir -p "${release}/root/.config/gtk-3.0"
  {
    echo '[Settings]'
    echo 'gtk-application-prefer-dark-theme = false'
    echo 'gtk-theme-name = Vimix'
    echo 'gtk-icon-theme-name = Vivacious-Colors-Dark'
    echo 'gtk-font-name = Droid Sans Bold 12'
  } > "${release}/root/.config/gtk-3.0/settings.ini"
  
  # Create splash screen configuration directory for user
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/.config/ghostbsd"
  chroot "${release}" su "${live_user}" -c "echo 'splash_enabled=yes' > /home/${live_user}/.config/ghostbsd/boot.conf"
  chroot "${release}" su "${live_user}" -c "echo 'esc_to_verbose=yes' >> /home/${live_user}/.config/ghostbsd/boot.conf"
}

community_setup_liveuser_interactive()
{
  # Set up user first
  set_user
  
  # Create desktop directory
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/Desktop"

  # Set up GBI installer desktop shortcut
  if [ -e "${release}/usr/local/share/applications/gbi.desktop" ] ; then
   chroot "${release}" su "${live_user}" -c  "cp -af /usr/local/share/applications/gbi.desktop /home/${live_user}/Desktop"
   chroot "${release}" su "${live_user}" -c  "chmod +x /home/${live_user}/Desktop/gbi.desktop"
   sed -i '' -e 's/NoDisplay=true/NoDisplay=false/g' "${release}/home/${live_user}/Desktop/gbi.desktop"
   # Trust desktop file for XFCE 4.18+ using checksum metadata
   if [ "${desktop}" = "xfce" ] ; then
     chroot "${release}" su - "${live_user}" -c '
       dbus-run-session -- sh -c "
         /usr/local/libexec/gvfsd >/dev/null 2>&1 &
         /usr/local/libexec/gvfsd-metadata >/dev/null 2>&1 &
         sleep 1
         f=\$HOME/Desktop/gbi.desktop
         sum=\$(sha256 -q \"\$f\")
         gio set -t string \"\$f\" metadata::xfce-exe-checksum \"\$sum\"
       "
     '
   fi
  fi
  
  # Create splash screen configuration directory for user
  chroot "${release}" su "${live_user}" -c "mkdir -p /home/${live_user}/.config/ghostbsd"
  chroot "${release}" su "${live_user}" -c "echo 'splash_enabled=yes' > /home/${live_user}/.config/ghostbsd/boot.conf"
  chroot "${release}" su "${live_user}" -c "echo 'esc_to_verbose=yes' >> /home/${live_user}/.config/ghostbsd/boot.conf"
  
  # Create desktop notification script for splash info
  cat > "${release}/home/${live_user}/Desktop/splash-info.txt" << 'EOF'
GhostBSD Interactive Splash Screen

Features:
- Press ESC during boot to view bootstrap messages
- Boot loader splash screen with 3-second delay
- Console splash during system initialization
- Animated service loading screen
- Clean transition to desktop environment

The splash screen provides a professional boot experience
while allowing developers and power users to access
detailed system messages when needed.
EOF
chroot "${release}" chown "${live_user}:wheel" "/home/${live_user}/Desktop/splash-info.txt"
}

community_setup_liveuser_interactive_gershwin()
{
  # Set up user first  
  set_user_gershwin
  
  # Update user directories
  chroot "${release}" su - "${live_user}" -c "xdg-user-dirs-update"
  
  # Create installer shortcut
  chroot "${release}" su - "${live_user}" -c "ln -sf /System/Applications/Installer.app \"/Users/${live_user}/Desktop/Installer.app\""
  
  # Create splash screen configuration directory for user
  chroot "${release}" su - "${live_user}" -c "mkdir -p /Users/${live_user}/.config/ghostbsd"
  chroot "${release}" su - "${live_user}" -c "echo 'splash_enabled=yes' > /Users/${live_user}/.config/ghostbsd/boot.conf"
  chroot "${release}" su - "${live_user}" -c "echo 'esc_to_verbose=yes' >> /Users/${live_user}/.config/ghostbsd/boot.conf"
  
  # Create desktop notification script for splash info (macOS-style)
  cat > "${release}/Users/${live_user}/Desktop/GhostBSD Splash Info.txt" << 'EOF'
GhostBSD Interactive Splash Screen

Features:
- Press ESC during boot to view bootstrap messages
- Boot loader splash screen with 3-second delay
- Console splash during system initialization  
- Animated service loading screen
- Clean transition to desktop environment

The splash screen provides a professional boot experience
while allowing developers and power users to access
detailed system messages when needed.
EOF
  chroot "${release}" chown "1100:wheel" "/Users/${live_user}/Desktop/GhostBSD Splash Info.txt"
}
