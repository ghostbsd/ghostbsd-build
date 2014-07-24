#!/bin/sh

set -e -u

if [ -z "${LOGFILE:-}" ]; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

# Creating pkg for GhostBSD. 
if [ "$(uname -p)" = "amd64" ] ; then
  PLATFORM=${PLATFORM:-"amd64"}
else
  PLATFORM=${PLATFORM:-"i386"}
fi

rm -rf /usr/obj/packages/${PLATFORM}

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
