#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.
#
# autologin.sh, v1.3, Sunday, June 29 2014 Eric


echo "# ghostbsd user autologin" >> ${BASEDIR}/etc/gettytab
echo "ghostbsd:\\" >> ${BASEDIR}/etc/gettytab
echo ":al=ghostbsd:ht:np:sp#115200:" >> ${BASEDIR}/etc/gettytab

sed -i "" "/ttyv0/s/Pc/ghostbsd/g" ${BASEDIR}/etc/ttys

echo "xconfig" >> ${BASEDIR}/home/ghostbsd/.cshrc


