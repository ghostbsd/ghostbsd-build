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

acpi_disable()
{
  # test condiion to see if computer was started with acpi disabled
  sed -i "" -e 's/# hint.acpi.0.disabled="1"/hint.acpi.0.disabled="1"/g' /boot/loader.conf
}

revert_slim()
{
  # remove ghostbsd user from slim.conf and autologin
  if [ -f /usr/local/etc/slim.conf ] ; then
    if grep -q '#slim' /etc/rc.conf; then
      sed -i "" -e 's/#slim_enable="YES"/slim_enable="YES"/g' /etc/rc.conf
    else
      echo 'slim_enable="YES"' >> /etc/rc.conf
    fi
    for home in `ls /usr/home`
    do
      echo 'exec $1' > /usr/home/$home/.xinitrc
      chown $home:$home /usr/home/$home/.xinitrc
    done
    sed -i '' -e "s/auto_login          yes/#auto_login          no/g"\
    -e  "s/default_user        ghostbsd/#default_user        none/g" \
    /usr/local/etc/slim.conf
  fi
}

revert_kdm()
{
if [ -f /usr/local/share/config/kdm/kdmrc ]; then
     sed -i '' -e "s/AutoLoginEnable=true/#AutoLoginEnable=true/g"\
     -e  "s/AutoLoginAgain=true/#AutoLoginAgain=true/g" \
     -e  "s/AutoLoginUser=ghostbsd/#AutoLoginUser=fred/g" \
     /usr/local/share/config/kdm/kdmrc
fi
}

revert_gdm()
{
if [ -f /usr/local/etc/gdm/custom.conf.sample ] ; then
        cp -af /usr/local/etc/gdm/custom.conf.sample /usr/local/etc/gdm/custom.conf
fi
}

fix_perms()
{
# fix permissions for kdm
if [ -d /usr/local/share/ghostbsd/kde-settings ]; then
    chmod 755 /var/lib/kdm
fi

# fix permissions for tmp dirs
chmod 1777 /var/tmp
chmod 1777 /tmp
}

rem_virtualbox()
{
# Check if we are in virtualbox to enable vbox-guest-additions
cat /tmp/.ifvbox | grep -q "True"
if  [ $? -ne 0 ] ; then
    pkg delete  -y virtualbox-ose-additions
fi
}

remove_ghostbsd_user()
{
  pw userdel -n ghostbsd
  rm -rf /home/ghostbsd
}

# Adding kern.vty=vt to 10_kfreebsd
sed -i '' '/set kFreeBSD.vfs.root.mountfrom.options=rw/a\
\       set kFreeBSD.kern.vty=vt\
\       set kFreeBSD.hw.psm.synaptics_support="1"\
' /usr/local/etc/grub.d/10_kfreebsd

# Replassing FreeBSD by GhostBSD
sed -i '' 's/OS="FreeBSD"/OS="GhostBSD"/g' /usr/local/etc/grub.d/10_kfreebsd

# Removing livecd hostname.
( echo 'g/hostname="livecd"/d' ; echo 'wq' ) | ex -s /etc/rc.conf

rm -f /usr/local/etc/xdg/autostart/umountghostbsd.desktop

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

purge_live_settings
set_sudoers
#acpi_disable
revert_slim
revert_kdm
revert_gdm
fix_perms
rem_virtualbox
remove_ghostbsd_user
clean_root_and_auto_login
