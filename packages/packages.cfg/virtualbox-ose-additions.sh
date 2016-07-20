#!/bin/sh

# disable virtualbox guest adittions in rc.conf
echo 'vboxguest_enable="NO"' >> /etc/rc.conf
echo 'vboxservice_enable="NO"' >> /etc/rc.conf
