#!/bin/sh

set -e -u

default_ghostbsd_rc_conf()
{
  cp  "${release}/etc/rc.conf" "${release}/etc/rc.conf.ghostbsd"
}

set_sudoers()
{
  sed -i "" -e 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' "${release}/usr/local/etc/sudoers"
  sed -i "" -e 's/# %sudo/%sudo/g' "${release}/usr/local/etc/sudoers"
}

# NEW FUNCTION FOR QUIET BOOT SETUP
setup_quiet_boot()
{
  # Suppress kernel messages during early boot
  echo 'kern.msgbuf_show_timestamp=0' >> "${release}/etc/sysctl.conf"
  echo 'kern.log_console_output=0' >> "${release}/etc/sysctl.conf"
  
  # Add quiet boot options to loader.conf if not already present
  if ! grep -q "boot_verbose" "${release}/boot/loader.conf" 2>/dev/null; then
    cat >> "${release}/boot/loader.conf" << 'EOF'

# Quiet boot options
boot_verbose="NO"
autoboot_delay="3"
EOF
  fi
}

# NEW FUNCTION FOR LOADER SPLASH CONFIGURATION
setup_loader_splash()
{
  # Loader splash disabled - "ghostbsd" is not a valid compiled brand
  # The boot/loader.conf template already has the necessary configuration
  :  # no-op
}

# NEW FUNCTION FOR BOOT MENU CUSTOMIZATION
setup_boot_menu()
{
  # Create custom boot menu configuration
  cat > "${release}/boot/menu.rc" << 'EOF'
\ Boot Menu for GhostBSD Live System
\ ESC to interrupt autoboot, or any other key to boot immediately.

only forth definitions also support-functions

: init-menu
   ." Loading GhostBSD..." cr
   ." Press ESC for boot options, or any key to continue..." cr
;

: (boot-menu)
   init-menu
   500 ms
   key? if
     drop exit
   then
   autoboot
;

: boot-menu
   (boot-menu)
;
EOF

  # Make it executable
  chmod 644 "${release}/boot/menu.rc"
}

final_setup()
{
  default_ghostbsd_rc_conf
  set_sudoers
  setup_quiet_boot
  setup_loader_splash
  setup_boot_menu
}
