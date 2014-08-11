#!/bin/sh
#    Author: Eric Turgeon
# Copyright: 2014 GhostBSD
#
# Update and create package for GhostBSD

#set -e -u

pkgfile="conf/packages"
pkgaddcmd="pkg install -yf"

portupgrade -crf xorg-minimal xorg-drivers

# Update GhostBSD pkg
while read pkgc; do
  if [ -n "${pkgc}" ]; then
    if [ "${pkgc}" = "xorg-minimal" ]; then
      echo "Pass $pkgc"
    elif [ "${pkgc}" = "xorg-drivers" ]; then
      echo "Pass $pkgc"
    else
      $pkgaddcmd $pkgc
    fi
  fi
done < $pkgfile
