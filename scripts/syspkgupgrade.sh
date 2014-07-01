#!/bin/sh
#    Author: Eric Turgeon
# Copyright: 2014 GhostBSD
#
# Update and create package for GhostBSD

pkgfile="conf/packages"
pkgaddcmd="pkg install -yf "

# Update GhostBSD pkg
while read pkgc; do
  if [ -n "${pkgc}" ]; then
    if [ "$(uname -p)" = "amd64" ]; then
      if [ "${pkgc}" = "xorg-minimal" ]; then
        echo "Pass $pkgc"
      elif [ "${pkgc}" = "xorg-drivers" ]; then
        echo "Pass $pkgc"
      else 
        $pkgaddcmd $pkgc
      fi
    else
      $pkgaddcmd $pkgc
    fi   
  fi
done < $pkgfile

# Updating remaining pkg from ports.

## Remove Gnome and Mate in .desktop.
Applications=`ls /usr/local/share/applications/`

for desktop in $Applications
do
  chmod 755 /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=Gnome;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/GNOME;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=//g' /usr/local/share/applications/$desktop
  chmod 555 /usr/local/share/applications/$desktop
done

## Creating pkg for GhostBSD. 
if [ "$(uname -p)" = "amd64" ]; then
  PLATFORM=${PLATFORM:-"amd64"}
else
  PLATFORM=${PLATFORM:-"i386"}
fi

if [ -d "/usr/obj/packages/${PLATFORM}" ]; then
  rm -rf /usr/obj/packages/${PLATFORM}/*
else
  mkdir -p /usr/obj/packages/${PLATFORM}
fi
for e in `pkg info | awk '{print $1}'`; do
  este=`ls -l /usr/obj/packages/${PLATFORM} | awk '{print $9}'| grep $e`
  echo $este
  if [ "${este}" = "${e}.txz" ]; then
    echo "Package "$e" is allready in /usr/obj/packages/${PLATFORM}"
  else
    echo "Creating backup package(s) "$e" /usr/obj/packages/${PLATFORM}"
    cd /usr/obj/packages/${PLATFORM} && pkg create $e
    echo "Package "$e" was created..."
  fi
done
