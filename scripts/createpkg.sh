#!/bin/sh
# Remove Gnome and Mate in .desktop.
GhostBSD=`ls /usr/local/share/applications/`for desktop in $GhostBSD
do
  chmod 755 /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=Gnome;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/GNOME;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=//g' /usr/local/share/applications/$desktop
  chmod 555 /usr/local/share/applications/$desktop
done

# Creating pkg for GhostBSD. 
if [ "$(uname -p)" = "amd64" ] ; then
  PLATFORM=${PLATFORM:-"amd64"}
else
  PLATFORM=${PLATFORM:-"i386"}
fi

mkdir -p /usr/obj/packages/${PLATFORM} 
for e in `pkg info | awk '{print $1}'`; do
  este=`ls -l /usr/obj/packages/${PLATFORM} | awk '{print $9}'| grep $e`
  echo $este
  if [ "${este}" = "${e}.txz" ] ; then
    echo "Package ${e} is allready in /usr/obj/packages/${PLATFORM}"
  else
    echo "Creating backup package(s) ${e} /usr/obj/packages/${PLATFORM}"
    cd /usr/obj/packages/${PLATFORM} && pkg create $e
    echo "Package "$e" was created..."
  fi
done
