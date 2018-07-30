#!/bin/sh
# Config which clean the system after the installation

# removing the old network configuration
purge_live_settings()
{
  pkg delete -y mate-live-settings
  # Removing livecd hostname.
  ( echo 'g/hostname="livecd"/d' ; echo 'wq' ) | ex -s /etc/rc.conf
  rm -f /usr/local/etc/xdg/autostart/umountghostbsd.desktop
}

set_sudoers()
{
  sed -i "" -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /usr/local/etc/sudoers
  sed -i "" -e 's/# %sudo/%sudo/g' /usr/local/etc/sudoers
}

fix_perms()
{
  # fix permissions for tmp dirs
  chmod 1777 /var/tmp
  chmod 1777 /tmp
}

remove_ghostbsd_user()
{
  pw userdel -n ghostbsd
  rm -rf /usr/home/ghostbsd
  ( echo 'g/# ghostbsd user autologin' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/ghostbsd:\\"/d' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/:al=ghostbsd:ht:np:sp#115200:/d' ; echo 'wq' ) | ex -s /etc/gettytab
  sed -i "" "/ttyv0/s/ghostbsd/Pc/g" /etc/ttys
}

PolicyKit_setting()
{
# Setup PolicyKit for mounting device.
printf '<?xml version="1.0" encoding="UTF-8"?> <!-- -*- XML -*- -->

<!DOCTYPE pkconfig PUBLIC "-//freedesktop//DTD PolicyKit Configuration 1.0//EN"
"http://hal.freedesktop.org/releases/PolicyKit/1.0/config.dtd">

<!-- See the manual page PolicyKit.conf(5) for file format -->

<config version="0.1">
  <match user="root">
    <return result="yes"/>
  </match>
  <define_admin_auth group="wheel"/>
  <match action="org.freedesktop.hal.power-management.shutdown">
    <return result="yes"/>
  </match>
  <match action="org.freedesktop.hal.power-management.reboot">
    <return result="yes"/>
  </match>
  <match action="org.freedesktop.hal.power-management.suspend">
    <return result="yes"/>
  </match>
  <match action="org.freedesktop.hal.power-management.hibernate">
    <return result="yes"/>
  </match>
  <match action="org.freedesktop.hal.storage.mount-removable">
    <return result="yes"/>
  </match>
  <match action="org.freedesktop.hal.storage.mount-fixed">
    <return result="yes"/>
  </match>
  <match action="org.freedesktop.hal.storage.eject">
    <return result="yes"/>
  </match>
  <match action="org.freedesktop.hal.storage.unmount-others">
    <return result="yes"/>
  </match>
</config>
' > /usr/local/etc/PolicyKit/PolicyKit.conf
}

set_dm()
{
  rc-update add slim default
}


purge_live_settings
set_sudoers
fix_perms
remove_ghostbsd_user
PolicyKit_setting
set_dm
