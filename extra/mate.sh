#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# mate.sh,v 1.0 Fri Sep  6 22:10:49 ADT 2013cd  Eric Turgeon
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

cp -f extra/mate/xinitrc ${BASEDIR}/usr/local/etc/X11/xinit/xinitrc 

# Remove gmplayer.desktop
if [ -f "/usr/local/share/applications/gmplayer.desktop" ]; then
  rm ${BASEDIR}/usr/local/share/applications/gmplayer.desktop
fi

# Ghostbsd theme.
cd ${BASEDIR}/usr/local/share/themes
rm -rf bubble TraditionalGreen WinMe TraditionalOk ThinIce Splint-Left Splint Spidey-Left Spidey Simply Simple Shiny
rm -rf Reverse Redmond Raleigh Quid PrintLarge Mist Metabox LowContrastLargePrint LowContrast LargePrint Inverted
rm -rf Industrial HighContrastLargePrintInverse HighContrastLargePrint HighContrastInverse HighContrast GreenLaguna
rm -rf Glossy Glider Fog Esco Emacs DustBlue Dopple-Left Dopple Crux ContrastLowLargePrint ContrastHighLargePrint
rm -rf ContrastHighInverse ContrastHigh ClearlooksRe ClearlooksClassic Clearlooks Bright Atlanta Atantla AlaDelta
rm -rf AgingGorilla
cd -
cp -prf extra/ghostbsd/themes ${BASEDIR}/usr/local/share/

#GhostBSD icons
rm -rf ${BASEDIR}/usr/local/share/icons/Quid
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrast
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrast-SVG
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrastInverse
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrastLargePrint
rm -rf ${BASEDIR}/usr/local/share/icons/HighContrastLargePrintInverse
rm -rf ${BASEDIR}/usr/local/share/icons/MateLargePrint
rm -rf ${BASEDIR}/usr/local/share/icons/LowContrastLargePrint
rm -rf ${BASEDIR}/usr/local/share/icons/Fog
rm -rf ${BASEDIR}/usr/local/share/icons/matefaenzacd
rm -rf ${BASEDIR}/usr/local/share/icons/matefaenzadark
rm -rf ${BASEDIR}/usr/local/share/icons/matefaenzagray
rm -f ${BASEDIR}/usr/local/share/icons/mate/icon-theme.cache
tar xfz extra/ghostbsd/icons.tar.gz -C ${BASEDIR}/usr/local/share

# Wallpapers remove MATE wallpaper.
rm -rf ${BASEDIR}/usr/local/share/backgrounds/mate

# GhostBSD dconf GhostBSD defaults file.
if [ -f ${BASEDIR}/usr/local/share/glib-2.0/schemas/org.mate.background.gschema.xml ] ; then
  sed -i "" "s@mate/desktop/Stripes.png@ghostbsd/GreenLeaf.jpg@" ${SHAREDIR}/glib-2.0/schemas/org.mate.background.gschema.xml
fi

if [ -f ${SHAREDIR}/glib-2.0/schemas/org.mate.interface.gschema.xml ] ; then
  sed -i "" "s@menta@Vibrancy-NonMono-Dark-Aqua@" ${SHAREDIR}/glib-2.0/schemas/org.mate.interface.gschema.xml
  sed -i "" "s@Menta@Ghomix@" ${SHAREDIR}/glib-2.0/schemas/org.mate.interface.gschema.xml
  sed -i "" "s@Sans@Sans Bold@" ${SHAREDIR}/glib-2.0/schemas/org.mate.interface.gschema.xml
fi

if [ -f ${SHAREDIR}/glib-2.0/schemas/org.mate.marco.gschema.xml ] ; then
  sed -i "" "s@Menta@Ghomix@" ${SHAREDIR}/glib-2.0/schemas/org.mate.macro.gschema.xml
fi

if [ -f ${SHAREDIR}/glib-2.0/schemas/org.mate.caja.gschema.xml ] ; then
  sed -i "" "s@Sans@Sans Bold@" ${SHAREDIR}/glib-2.0/schemas/org.mate.caja.gschema.xml
fi


#cp -prf extra/mate/org.mate.panel.toplevel.gschema.xml ${BASEDIR}/usr/local/share/glib-2.0/schemas/
cp -prf extra/mate/org.mate.terminal.gschema.xml ${BASEDIR}/usr/local/share/glib-2.0/schemas/

cp -prf extra/mate/org.mate.screensaver.gschema.xml ${BASEDIR}/usr/local/share/glib-2.0/schemas/
cp -prf extra/mate/panel-default-layout.mate ${SHAREDIR}/mate-panel/layouts/default.layout

# GhostBSD shose station.
cp -rf extra/mate/chose-station ${BASEDIR}/usr/local/share/chose-station
install -C extra/mate/chose-station/main.py ${BASEDIR}/usr/local/bin/chose-station
cp extra/mate/chose-station/chose-station.desktop ${BASEDIR}/usr/local/etc/xdg/autostart/

# Package Manager in Mate menu
#cp -prf extra/mate/mate-applications.menu ${BASEDIR}/usr/local/etc/xdg/menus/mate-applications.menu

# Compile schemas with glib
chroot ${BASEDIR} glib-compile-schemas /usr/local/share/glib-2.0/schemas/

# gksu configuration.
if [ -f ${BASEDIR}/usr/local/share/applications/gksu.desktop ] ; then
  /usr/bin/sed -i "" "s@/usr/bin/x-terminal-emulator@/usr/local/bin/mate-terminal@" ${SHAREDIR}applications/gksu.desktop
fi

# Set cursor theme instead of default from xorg
if [ -e ${BASEDIR}/usr/local/lib/X11/icons/default ] ; then
rm ${BASEDIR}/usr/local/lib/X11/icons/default 
fi
cd ${BASEDIR}/usr/local/lib/X11/icons
ln -sf $CURSOR_THEME default
cd -
