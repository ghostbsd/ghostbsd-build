#!/usr/bin/env sh

set -e -u

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

kernrel="`uname -r`"

case $kernrel in
  '12.1-STABLE')
    echo "Using correct kernel release" 1>&2
    ;;
  '12.1-PRERELEASE')
    echo "Using correct kernel release" 1>&2
    ;;
  '12.0-STABLE')
    echo "Using correct kernel release" 1>&2
    ;;
  *)
    echo "Using wrong kernel release. Use TrueOS 18.12 or GhostBSD 19 to build iso."
    exit 1
    ;;
esac

# Source our functions
. functions.sh

workspace
base
packages_software
#compress_packages
user
xorg
rc
extra_config
uzip
ramdisk
mfs
boot
image
