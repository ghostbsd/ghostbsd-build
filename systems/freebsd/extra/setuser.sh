#!/bin/sh
#
# Copyright (c) 2011 Dario Freni
#
# See COPYRIGHT for licence terms.
#
# adduser.sh,v 1.5_1 Friday, January 14 2011 13:06:55

set -e -u

setup_liveuser()
{
  chroot ${release} pw mod user liveuser -w none
  chroot ${release} pw groupadd autologin
  chroot ${release} pw groupmod autologin -M liveuser
  chroot ${release} su liveuser -c /usr/local/share/ghostbsd/common-live-settings/config-live-settings
}
