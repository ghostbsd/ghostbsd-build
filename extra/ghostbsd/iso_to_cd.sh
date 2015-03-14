#!/bin/sh
# Config which clean the system after the installation

# removing the old network configuration


rm -f /usr/bin/gbi 
rm -f /usr/bin/ginstall

# removing auto login, startx and X configuration.
GHOSTBSD=${GHOSTBSD:-"ghostbsd"}
( echo "g/# ghostbsd user autologin/d" ; echo 'wq' ) | ex -s /etc/gettytab
( echo "g/ghostbsd:\\/d" ; echo 'wq' ) | ex -s /etc/gettytab
( echo "g/:al=ghostbsd:ht:np:sp#115200:/d" ; echo 'wq' ) | ex -s /etc/gettytab
sed -i "" "/ttyv0/s/ghostbsd/Pc/g" /etc/ttys

sed -i '' 's@#pcdm_enable="YES"@pcdm_enable="YES"@g' /etc/rc.conf 

# Removing livecd hostname.
( echo 'g/hostname="livecd"/d' ; echo 'wq' ) | ex -s /etc/rc.conf

cd /home
LS=`ls`
cd -
for user in ${LS}
do


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
' > ${FSMNT}/usr/local/etc/PolicyKit/PolicyKit.conf

rm -f /usr/local/etc/xdg/autostart/chose-station.desktop
