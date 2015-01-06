#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# dm.sh,v 0.1
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

# Allow GDM auto login:
# printf "
# auth       required     pam_permit.so
# account    required     pam_nologin.so
# account    required     pam_unix.so
# session    required     pam_permit.so
# " > ${BASEDIR}/etc/pam.d/gdm-autologin

# Use a GDM config file which enables auto login as the live user:
# cp -f extra/dm/custom.conf ${BASEDIR}/usr/local/etc/gdm/custom.conf

# cp -f extra/ghostbsd/wallpapers/ghost_horizon.png ${BASEDIR}/usr/local/share/pixmaps/backgrounds/gnome/background-default.jpg

#slim experimentation.
#cp -f extra/dm/slim.conf ${BASEDIR}/usr/local/etc/slim.conf
#sed -i "" "/ttyv8/s/xdm/slim/g" ${BASEDIR}/etc/ttys
#sed -i "" "/ttyv8/s/off/on/g" ${BASEDIR}/etc/ttys

#Gconf GhostBSD defaults.
#mkdir -p /usr/local/etc/default
#rm -rf ${BASEDIR}/usr/local/etc/gconf/gconf.xml.defaults
#cp -f extra/dm/gnome-desktop-settings /usr/local/etc/default/
#cp -f extra/dm/get_settings /usr/local/etc/default/
#mkdir -p ${BASEDIR}/usr/local/etc/default
#sh /usr/local/etc/default/get_settings
#rm -rf /usr/local/etc/default
#cp -prf /usr/local/etc/gconf/* ${BASEDIR}/usr/local/etc/gconf

cp -rf extra/dm/default/* ${BASEDIR}/usr/local/share/PCDM/themes/default
#cp ${BASEDIR}/usr/local/share/PCDM/pcdm.conf.sample ${BASEDIR}/usr/local/share/PCDM/pcdm.conf

#sed -i "" "s@THEME_FILE=/usr/local/share/PCDM/themes/default/default.theme@THEME_FILE=/usr/local/share/PCDM/themes/default/default.theme@" ${BASEDIR}/usr/local/share/PCDM/pcdm.conf
#sed -i "" "s@ENABLE_AUTO_LOGIN=FALSE@ENABLE_AUTO_LOGIN=TRUE@" ${BASEDIR}/usr/local/share/PCDM/pcdm.conf
#sed -i "" "s@AUTO_LOGIN_USER=no-username@AUTO_LOGIN_USER=ghostbsd@" ${BASEDIR}/usr/local/share/PCDM/pcdm.conf

sed -i "" "s@: ${pcdm_enable:=no}@# : ${pcdm_enable:=no}@" ${BASEDIR}/usr/local/etc/rc.d/pcdm
printf "#####################################
#  PCDM CONFIGURATION FILE          #
# (/usr/local/etc/pcdm.conf.dist)   #
#####################################

## APPEARANCE SETTINGS ##
THEME_FILE=/usr/local/share/PCDM/themes/default/default.theme
SPLASHSCREEN_FILE=/usr/local/share/PCDM/themes/default/splashscreen.png

## Base Directories for files ##
DE_STARTUP_DIR=/usr/local/share/xsessions  #location for *.desktop entries for desktop environments(s)
DE_STARTUP_IMAGE_DIR=/usr/local/share/pixmaps   #location of images contained in *.desktop file (if not explicitly given)

## AUTO-LOGIN ##
## This presents a security risk - use carefully! ##
ENABLE_AUTO_LOGIN=TRUE        
AUTO_LOGIN_USER=ghostbsd
AUTO_LOGIN_PASSWORD=no-password

## VNC Remote Desktop SUPPORT ##
## This presents a security risk - use carefully! ##
ALLOW_REMOTE_LOGIN=FALSE

## Share the remote screen ##
REMOTE_SHARED_SCREEN=FALSE

## ADDITIONAL SETTINGS ##
ENABLE_VIEW_PASSWORD_BUTTON=FALSE  #enable the option to show the password as text when a button is held" > ${BASEDIR}/usr/local/share/PCDM/pcdm.conf
