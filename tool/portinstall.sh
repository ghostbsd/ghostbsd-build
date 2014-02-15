#!/bin/sh 

PLOGFILE="port_log"
pkgfile=`cat ports`
pkgaddcmd="portinstall -c"

if [ ! -f '/usr/local/bin/portupgrade' ]; then
  cd /usr/ports/ports-mgmt/portupgrade
  make config-recursive install clean
fi
 
#for pkgc in $pkgfile
#do
#
#done
sh ports

