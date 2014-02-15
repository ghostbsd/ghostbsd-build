#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# autologin.sh,v 1.2_1 Monday, January 31 2011 01:06:12 Eric
#
# Enable autologin of the $GHOSTBSD_ADDUSER user on the first terminal
#

GHOSTBSD_ADDUSER=${GHOSTBSD_ADDUSER:-"ghostbsd"}

echo "# ${GHOSTBSD_ADDUSER} user autologin" >> ${BASEDIR}/etc/gettytab
echo "${GHOSTBSD_ADDUSER}:\\" >> ${BASEDIR}/etc/gettytab
echo ":al=${GHOSTBSD_ADDUSER}:ht:np:sp#115200:" >> ${BASEDIR}/etc/gettytab

sed -i "" "/ttyv0/s/Pc/${GHOSTBSD_ADDUSER}/g" ${BASEDIR}/etc/ttys
echo 'if ($tty == ttyv0) then' >> ${BASEDIR}/home/ghostbsd/.cshrc
#echo 'if ($tty == ttyv0) then' >> ${BASEDIR}/home/ghostbsd/.shrc
echo "  sudo sh /usr/local/etc/card/xconfig.sh" >> ${BASEDIR}/home/ghostbsd/.cshrc
echo "  sudo chsh -s /usr/local/bin/fish ghostbsd" >> ${BASEDIR}/home/ghostbsd/.shrc
echo "  startx" >> ${BASEDIR}/home/ghostbsd/.cshrc
#echo "  startx" >> ${BASEDIR}/home/ghostbsd/.shrc
echo "endif" >> ${BASEDIR}/home/ghostbsd/.cshrc
#echo "endif" >> ${BASEDIR}/home/ghostbsd/.shrc
