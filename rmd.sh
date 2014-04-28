#!/bin/sh

# Remove Gnome and Mate in .desktop.

GhostBSD=`ls /usr/local/share/applications/`

for desktop in $GhostBSD
do
  chmod 755 /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=Gnome;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/GNOME;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=//g' /usr/local/share/applications/$desktop
  chmod 555 /usr/local/share/applications/$desktop
done


