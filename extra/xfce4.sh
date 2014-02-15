#!/bin/sh

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

cp -f extra/xfce4/xinitrc ${BASEDIR}/usr/local/lib/X11/xinit/xinitrc

# Removing gnome.desktop.
cd ${BASEDIR}/usr/local/share/xsessions
rm -rf gnome.desktop 
cd -

# Wallpapers
cp -prf extra/ghostbsd/wallpapers/* ${BASEDIR}/usr/local/share/backgrounds/xfce/
cp -f extra/ghostbsd/wallpapers/something_blue.jpg ${BASEDIR}/usr/local/share/backgrounds/xfce/xfce-blue.jpg


# XML seting for the default xfce.
cp -f extra/xfce4/default.xml ${BASEDIR}/usr/local/etc/xdg/xfce4/panel
cp -f extra/xfce4/xsettings.xml ${BASEDIR}/usr/local/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/

if [ -f ${BASEDIR}/usr/local/share/applications/gksu.desktop ] ; then
        /usr/bin/sed -i "" "s@/usr/bin/x-terminal-emulator@/usr/local/bin/xfce4-terminal@" ${BASEDIR}/usr/local/share/applications/gksu.desktop
fi

if [ -f ${BASEDIR}/usr/local/share/applications/cups.desktop ] ; then
        /usr/bin/sed -i "" "s@htmlview@firefox@" ${BASEDIR}/usr/local/share/applications/cups.desktop
fi

if [ -f ${BASEDIR}/usr/local/share/applications/evince.desktop ] ; then
        /usr/bin/sed -i "" "s@NoDisplay=true@NoDisplay=false@" ${BASEDIR}/usr/local/share/applications/evince.desktop
fi

# Cups adds.
cp -f extra/gnome/devfs.rules ${BASEDIR}/etc/
cat extra/gnome/make.conf >> ${BASEDIR}/etc/make.conf

#add sudo wheel permission
cp extra/gnome/sudoers ${BASEDIR}/usr/local/etc/

# To enable USB devices that are plugged in to be read/written
# by operators (i.e. the live user), this is needed:
if [ -z "$(cat ${BASEDIR}/etc/devd.conf| grep ugen[0-9])" ] ; then
    cat extra/gnome/devd.conf.extra >> ${BASEDIR}/etc/devd.conf
fi
if [ -z "$(cat ${BASEDIR}/etc/sysctl.conf| grep vfs.usermount)" ] ; then
    echo "vfs.usermount=1" >> ${BASEDIR}/etc/sysctl.conf
fi

# Set cursor theme instead of default from xorg
if [ -e ${BASEDIR}/usr/local/lib/X11/icons/default ] ; then
rm ${BASEDIR}/usr/local/lib/X11/icons/default 
fi
cd ${BASEDIR}/usr/local/lib/X11/icons
ln -sf $CURSOR_THEME default
cd - 

# Icons
tar xfz extra/ghostbsd/icons.tar.gz -C ${BASEDIR}/usr/local/share

# Theme
cp -prf extra/ghostbsd/themes ${BASEDIR}/usr/local/share/

# Add bxpkg to the menue
cp -f extra/gnome/bxpkg-${ARCH}.desktop ${BASEDIR}/usr/local/share/applications/bxpkg.desktop
cp -f extra/gnome/m_icon.png ${BASEDIR}/usr/local/share/pixmaps/


