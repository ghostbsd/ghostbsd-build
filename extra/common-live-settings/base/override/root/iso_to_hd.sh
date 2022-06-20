#!/bin/sh
# Configure which clean the system after the installation
echo "Starting iso_to_hdd.sh"

if [ -f "/usr/local/bin/mate-session" ]; then
  desktop='mate'
elif [ -f "/usr/local/bin/startxfce4" ]; then
  desktop='xfce'
fi

remove_ghostbsd_user()
{
  echo "Remove ghostbsd user"
  pw userdel -n ghostbsd -r
  echo "Remove auto login"
  ( echo 'g/# ghostbsd user autologin' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/ghostbsd:\\"/d' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/:al=ghostbsd:ht:np:sp#115200:/d' ; echo 'wq' ) | ex -s /etc/gettytab
  sed -i "" "/ttyv0/s/ghostbsd/Pc/g" /etc/ttys
}

setup_dm_and_xinitrc()
{
  echo "setup xinitrc for ${desktop}"
  case $desktop in
    mate)
      echo 'exec mate-session' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec mate-session' > /usr/home/${user}/.xinitrc
        chown ${user}:${user} /usr/home/${user}/.xinitrc
      done ;;
    xfce)
      echo 'exec startxfce4' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec startxfce4' > /usr/home/${user}/.xinitrc
        chown ${user}:${user} /usr/home/${user}/.xinitrc
      done ;;
  esac

  echo "Enable LightDM at boot"
  # for unknown reason sysrc does not work in this script
  sed -i '' 's/lightdm_enable="NO"/lightdm_enable="YES"/g' /etc/rc.conf
}

restore_settings()
{
  echo "Restore automount_devd.conf and automount_devd_localdisks.conf"
  mv /usr/local/etc/devd/automount_devd.conf.skip /usr/local/etc/devd/automount_devd.conf
  mv /usr/local/etc/devd/automount_devd_localdisks.conf.skip /usr/local/etc/devd/automount_devd_localdisks.conf
}

remove_ghostbsd_user
setup_dm_and_xinitrc
restore_settings
