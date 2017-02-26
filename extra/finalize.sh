#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# finalize.sh,v 1.0 Wed 17 Jun 19:42:49 ADT 2015cd  Ovidiu Angelescu
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi


cursor_theme()
{
# Set cursor theme instead of default from xorg
# to do with alternatives if possible from common installed settings
  if [ -e ${BASEDIR}/usr/local/lib/X11/icons/default ] ; then
    rm ${BASEDIR}/usr/local/lib/X11/icons/default
  fi
  if [ -e ${BASEDIR}/usr/local/lib/X11/icons ] ; then
  cd ${BASEDIR}/usr/local/lib/X11/icons
  ln -sf $CURSOR_THEME default
  fi
  cd -
}

clean_desktop_files()
{
# Remove Gnome and Mate from ShowOnly in *.desktop
# needed for update-station
DesktopBSD=`ls ${BASEDIR}/usr/local/share/applications/ | grep -v libreoffice | grep -v kde4 | grep -v screensavers`
for desktop in $DesktopBSD; do
  sed -i "" -e 's/OnlyShowIn=Gnome;//g' ${BASEDIR}/usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=MATE;//g' ${BASEDIR}/usr/local/share/applications/$desktop
  sed -i "" -e 's/GNOME;//g' ${BASEDIR}/usr/local/share/applications/$desktop
  sed -i "" -e 's/MATE;//g' ${BASEDIR}/usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=//g' ${BASEDIR}/usr/local/share/applications/$desktop
done
}

default_ghostbsd_rc_conf()
{
  cp  ${BASEDIR}/etc/rc.conf ${BASEDIR}/etc/rc.conf.ghostbsd
}

set_sudoers()
{
  sed -i "" -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' ${BASEDIR}/usr/local/etc/sudoers
  sed -i "" -e 's/# %sudo/%sudo/g' ${BASEDIR}/usr/local/etc/sudoers
}

config_packages()
{
pkgfile="${PACK_PROFILE}-settings"
CPLOGFILE="${BASEDIR}/mnt/.log_copypkgconfig"
PLOGFILE=".log_pkgconfig"

if [ -f /tmp/${pkgfile} ] ; then

cp /tmp/${pkgfile}  ${BASEDIR}/mnt/

# copy config scripts for needed packages
while read pkgc; do
    if [ -n "${pkgc}" ] ; then
        if [ -f "${LOCALDIR}/packages/packages.cfg/$pkgc.sh" ] ; then
        cp -af ${LOCALDIR}/packages/packages.cfg/$pkgc.sh ${BASEDIR}/mnt/
        if [ $? -ne 0 ] ; then
            echo "$pkgc.sh configuration file not found" >> ${CPLOGFILE} 2>&1
            echo "$pkgc.sh configuration file not found"
            exit 1
        else
            echo "$pkgc.sh configuration file found" >> ${CPLOGFILE} 2>&1
            echo "$pkgc.sh configuration file found"
        fi
        fi
    fi
done < /tmp/${pkgfile}


# config packages in chroot
cat > ${BASEDIR}/mnt/configpkg.sh << "EOF"
#!/bin/sh

# pkg config part
cd /mnt
PLOGFILE=".log_pkgconfig"
pkgfile="${PACK_PROFILE}-settings"

# run config scripts for needed packages
while read pkgc; do
    if [ -n "${pkgc}" ] ; then
        /bin/sh /mnt/${pkgc}.sh
        if [ $? -ne 0 ] ; then
            echo "$pkgc configuration failed" >> ${PLOGFILE} 2>&1
            echo "$pkgc configuration failed"
            exit 1
        else
            echo "$pkgc configuration done" >> ${PLOGFILE} 2>&1
            echo "$pkgc configuration done"
            rm /mnt/${pkgc}.sh
        fi
    fi
done < $pkgfile

rm configpkg.sh
rm $pkgfile
EOF

# run configpkg.sh in chroot to add packages
chrootcmd="chroot ${BASEDIR} sh /mnt/configpkg.sh"
$chrootcmd

# save logs
mv ${BASEDIR}/mnt/${PLOGFILE} ${MAKEOBJDIRPREFIX}/${LOCALDIR}
mv ${CPLOGFILE} ${MAKEOBJDIRPREFIX}/${LOCALDIR}
fi
}

root_dot_xinitrc()
{
echo 'slim_enable="YES"' >> ${BASEDIR}/etc/rc.conf
echo 'exec $1' > ${BASEDIR}/root/.xinitrc
# if [ "${PACK_PROFILE}" == "mate" ] ; then
#  echo "exec ck-launch-session mate-session" > ${BASEDIR}/root/.xinitrc
# elif [ "${PACK_PROFILE}" == "xfce" ] ; then
#  echo "exec ck-launch-session startxfce4" > ${BASEDIR}/root/.xinitrc
# fi

}

set_doas()
{
  sed -i "" '1 i\
  permit nopass keepenv root\
  ' ${BASEDIR}/usr/local/etc/doas.conf
  sed -i "" '1 i\
  permit :wheel\
  ' ${BASEDIR}/usr/local/etc/doas.conf
}

#remove_desktop_entries
clean_desktop_files
# rm_fbsd_pcsysinstall
cursor_theme
# dm_enable
default_ghostbsd_rc_conf
set_sudoers
set_doas
config_packages
root_dot_xinitrc
