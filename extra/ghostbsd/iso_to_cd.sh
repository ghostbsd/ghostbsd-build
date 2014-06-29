#!/bin/sh
# Config which clean the system after the installation

# removing the old network configuration


rm -f /usr/bin/gbi 
rm -f /usr/bin/ginstall

# removing auto login, startx and X configuration.
GHOSTBSD=${GHOSTBSD:-"ghostbsd"}
( echo "g/# ${GHOSTBSD} user autologin/d" ; echo 'wq' ) | ex -s ${FSMNT}/etc/gettytab
( echo "g/${GHOSTBSD}:\\/d" ; echo 'wq' ) | ex -s ${FSMNT}/etc/gettytab
( echo "g/:al=${GHOSTBSD}:ht:np:sp#115200:/d" ; echo 'wq' ) | ex -s ${FSMNT}/etc/gettytab
sed -i "" "/ttyv0/s/${GHOSTBSD}/Pc/g" ${FSMNT}/etc/ttys
rm -rf ${FSMNT}/usr/local/etc/card

sed -i '' 's@#gdm_enable="YES"@gdm_enable="YES"@g' ${FSMNT}/etc/rc.conf 

cd /home
LS=`ls`
cd -
for user in ${LS}
do
  printf "file:///home/${user}/Documents Documents
file:///home/${user}/Downloads Downloads
file:///home/${user}/Movies Movies
file:///home/${user}/Music Music
file:///home/${user}/Pictures Pictures
" > /home/${user}/.gtk-bookmarks
  chown ${user} /home/${user}/.gtk-bookmarks
  chmod 755/home/${user}/.gtk-bookmarks
  mkdir /home/${user}/Documents
  chown ${user} /home/${user}/Documents
  chmod 755 /home/${user}/Documents
  mkdir /home/${user}/Downloads
  chown ${user} /home/${user}/Downloads
  chmod 755 /home/${user}/Downloads
  mkdir /home/${user}/Movies
  chown ${user} /home/${user}/Movies
  chmod 755 /home/${user}/Movies
  mkdir /home/${user}/Music
  chown ${user} /home/${user}/Music
  chmod 755 /home/${user}/Music
  mkdir /home/${user}/Pictures
  chown ${user} /home/${user}/Pictures
  chmod 755 /home/${user}/Pictures
done

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

rm -f /config.sh
