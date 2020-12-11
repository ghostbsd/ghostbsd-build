#!/bin/sh
# Configure which clean the system after the installation
echo "Starting iso_to_hdd.sh"

if [ -f "/usr/local/bin/mate-session" ]; then
  desktop='mate'
elif [ -f "/usr/local/bin/startxfce4" ]; then
  desktop='xfce'
elif [ -f "/usr/local/bin/cinnamon-session" ]; then
  desktop='cinnamon'
elif [ -f "/usr/local/bin/startplasma-x11" ]; then
  desktop='kde'
fi

remove_ghostbsd_user()
{
  pw userdel -n ghostbsd
  rm -rf /usr/home/ghostbsd
  ( echo 'g/# ghostbsd user autologin' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/ghostbsd:\\"/d' ; echo 'wq' ) | ex -s /etc/gettytab
  ( echo 'g/:al=ghostbsd:ht:np:sp#115200:/d' ; echo 'wq' ) | ex -s /etc/gettytab
  sed -i "" "/ttyv0/s/ghostbsd/Pc/g" /etc/ttys
}

setup_dm_and_xinitrc()
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
      echo 'exec ck-launcher-session startplasma-x11' > /root/.xinitrc
      for user in `ls /usr/home/` ; do
        echo 'exec ck-launcher-session startplasma-x11' > /usr/home/${user}/.xinitrc
        chown ${user}:wheel /usr/home/${user}/.xinitrc
      done ;;
  esac
  rc-update add lightdm default
}

disable_syscons()
{
  kenv | grep -q 'hw.syscons.disable'
  if [ $? -eq 0 ] ; then
    echo "hw.syscons.disable=1" >> /boot/loader.conf
  fi
}

remove_ghostbsd_user
setup_dm_and_xinitrc
disable_syscons
