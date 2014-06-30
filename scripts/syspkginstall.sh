#!/bin/sh 

PLOGFILE=".log_pkginstall"
pkgfile="packages"
pkgaddcmd="pkg install -y"


while read pkgc; do
    if [ -n "${pkgc}" ] ; then
    echo "Installing package $pkgc"
    $pkgaddcmd $pkgc 
    #>> ${PLOGFILE} 2>&1
    fi
done < $pkgfile

