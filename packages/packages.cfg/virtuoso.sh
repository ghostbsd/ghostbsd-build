#!/bin/sh

# copy virtuoso config file
cp /usr/local/lib/virtuoso/db/virtuoso.ini.sample /usr/local/lib/virtuoso/db/virtuoso.ini

# enable virtuoso in rc.conf
echo 'virtuoso_enable="YES"' >> /etc/rc.conf
echo 'virtuoso_config="/usr/local/lib/virtuoso/db/virtuoso.ini"' >> /etc/rc.conf
