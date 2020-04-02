#!/bin/sh
# Configure which clean the system after the installation
echo "Starting iso_to_hdd.sh"

desktop=$(cat /usr/local/share/ghostbsd/desktop)

# removing the old network configuration
purge_live_settings()
{
  case $desktop in
    mate)
      rm /usr/local/share/glib-2.0/schemas/92_org.gnome.desktop.screensaver.gschema.override
      rm /usr/local/share/glib-2.0/schemas/92_org.mate.lockdown.gschema.override
      rm /usr/local/share/glib-2.0/schemas/92_org.mate.SettingsDaemon.plugins.housekeeping.gschema.override
      glib-compile-schemas /usr/local/share/glib-2.0/schemas ;;
    xfce)
      pkg delete -y xfce-live-settings ;;
    cinnamon)
      ;;
    kde)
      ;;
  esac
  # Removing livecd hostname.
  ( echo 'g/hostname="livecd"/d' ; echo 'wq' ) | ex -s /etc/rc.conf
  # rc-update add xconfig default
}

set_sudoers()
{
  sed -i "" -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /usr/local/etc/sudoers
  sed -i "" -e 's/# %sudo/%sudo/g' /usr/local/etc/sudoers
  sed -i "" -e "s/# ${user} ALL=(ALL) NOPASSWD: ALL/g" /usr/local/etc/sudoers/${user}
}

set_nohistory()
{
  sed -i "" -e "s/# export HISTSIZE=0/g" /home/${user}/.bashrc
  sed -i "" -e "s/# export HISTSIZE=0/g" /root/.bashrc
  sed -i "" -e "s/# export HISTFILESIZE=0/g" /home/${user}/.bashrc
  sed -i "" -e "s/# export HISTFILESIZE=0/g" /root/.bashrc
  sed -i "" -e "s/# export SAVEHIST=0/g" /home/${user}/.bashrc
  sed -i "" -e "s/# export SAVEHIST=0/g" /root/.bashrc
}

fix_perms()
{
  # fix permissions for tmp dirs
  chmod -Rv 1777 /var/tmp
  chmod -Rv 1777 /tmp
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

setup_slim_and_xinitrc()
{
  echo 'exec mate-session' > /root/.xinitrc
  sed -i "" -e 's/#default_user  /default_user  /g' /usr/local/etc/slim.conf
  for user in `ls /usr/home/` ; do
    echo 'exec mate-session' > /usr/home/${user}/.xinitrc
    chown ${user}:wheel /usr/home/${user}/.xinitrc
    sed -i "" -e "s/simone/${user}/g" /usr/local/etc/slim.conf
  done
  rc-update add slim default
  sed -i "" -e 's/sessiondir    /#sessiondir    /g' /usr/local/etc/slim.conf
}

setup_lightdm_and_xinitrc()
{
  case $desktop in
    mate)
      echo 'exec mate-session' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec mate-session' > /usr/home/${user}/.xinitrc
        chown ${user}:wheel /usr/home/${user}/.xinitrc
      done ;;
    xfce)
      echo 'exec startxfce4' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec startxfce4' > /usr/home/${user}/.xinitrc
        chown ${user}:wheel /usr/home/${user}/.xinitrc
      done ;;
    cinnamon)
      echo 'exec cinnamon-session' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec cinnamon-session' > /usr/home/${user}/.xinitrc
        chown ${user}:wheel /usr/home/${user}/.xinitrc
      done ;;
    kde)
      echo 'exec startplasma-x11' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec startplasma-x11' > /usr/home/${user}/.xinitrc
        chown ${user}:wheel /usr/home/${user}/.xinitrc
      done ;;
  esac
  rc-update add lightdm default
}

setup_sddm_and_xinitrc()
{
  case $desktop in
     kde)
      echo 'exec startplasma-x11' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec startplasma-x11' > /usr/home/${user}/.xinitrc
        chown ${user}:wheel /usr/home/${user}/.xinitrc
      done ;;
  esac
  rc-update add sddm default
}

set_qt5ct()
{
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /home/${user}/.xinitrc
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /root/.xinitrc
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /home/${user}/.xprofile
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /root/.xprofile
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /home/${user}/.bashrc
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /root/.bashrc
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /home/${user}/.bash_profile
  echo "export QT_QPA_PLATFORMTHEME=qt5ct" > /root/.bash_profile
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
set_nohistory
fix_perms
remove_ghostbsd_user
PolicyKit_setting
setup_slim_and_xinitrc
#case $desktop in
#  kde)
#    setup_sddm_and_xinitrc
#    set_qt5ct
#    ;;
#  *)
#    setup_lightdm_and_xinitrc
#    ;;
#esac
