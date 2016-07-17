#!/bin/sh

# add to webcamd group ghostbsd user
pw groupmod webcamd -m ghostbsd

# enable webcamd in rc.conf
echo 'webcamd_enable="YES"' >> /etc/rc.conf
echo 'cuse4bsd_load="YES"' >> /boot/loader.conf
