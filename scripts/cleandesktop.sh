#!/bin/sh

set -e -u

if [ -z "${LOGFILE:-}" ]; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

# Remove Gnome and Mate in .desktop.
GhostBSD=`ls /usr/local/share/applications/ | grep -v libreoffice`

for desktop in $GhostBSD; do
  chmod 755 /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=Gnome;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/GNOME;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=//g' /usr/local/share/applications/$desktop
  chmod 555 /usr/local/share/applications/$desktop
done
