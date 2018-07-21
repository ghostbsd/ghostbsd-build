#!/bin/sh

set -e -u

setup_liveuser()
{
  chroot ${release} pw mod user liveuser -w none
  chroot ${release} pw groupadd autologin
  chroot ${release} pw groupmod autologin -M liveuser
  chroot ${release} su liveuser -c /usr/local/share/ghostbsd/common-live-settings/config-live-settings
}
