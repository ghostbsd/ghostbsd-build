#!/bin/sh
# Config which clean the system after the installation

# removing the old network configuration

if [ -f /usr/local/etc/default/distro ] ; then
. /usr/local/etc/default/distro
fi

purge_live_settings()
{
  GBSDFLAVOUR=$(cat /usr/local/etc/default/distro | grep FLAVOUR | cut -d = -f2)
  pkg delete -y $GBSDFLAVOUR-live-settings
  pkg delete -y ghostbsd-live-common-settings
  # Removing livecd hostname.
  ( echo 'g/hostname="livecd"/d' ; echo 'wq' ) | ex -s /etc/rc.conf
  rm -f /usr/local/etc/xdg/autostart/umountghostbsd.desktop
}

clean_root_and_auto_login()
{
  # sed -i "" -e 's/root/Pc/g' /etc/ttys
  rm -rf /root/cardDetect /root/functions.sh /root/sysconfig.sh /root/sysutil.sh /root/sysutil.sh /root/.login /root/Desktop/gbi.desktop
  echo 'exec $1'  > /root/.xinitrc
}

set_sudoers()
{
  sed -i "" -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /usr/local/etc/sudoers
  sed -i "" -e 's/# %sudo/%sudo/g' /usr/local/etc/sudoers
}

revert_lightdm()
{
  sed -i '' -e "s/autologin-user=ghostbsd/#autologin-user=ghostbsd/g"\
  -e  "s/autologin-user-timeout=0/#autologin-user-timeout=0/g" \
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
  ( echo 'g/# ${liveuser} user autologin' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/${liveuser}:\\"/d' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/:al=${liveuser}:ht:np:sp#115200:/d' ; echo 'wq' ) | ex -s /etc/gettytab
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

purge_live_settings
set_sudoers
revert_lightdm
fix_perms
remove_ghostbsd_user
PolicyKit_setting
