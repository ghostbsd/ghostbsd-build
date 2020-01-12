#!/usr/bin/env sh

set -e -u

export cwd="`realpath | sed 's|/scripts||g'`"
# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

kernrel="`uname -r`"

case $kernrel in
  '12.1-STABLE'|'12.1-PRERELEASE'|'12.0-STABLE') ;;
  *)
    echo "Using wrong kernel release. Use TrueOS 18.12 or GhostBSD 19 to build iso."
    exit 1
    ;;
esac

desktop_list=`ls ${cwd}/packages | tr '\n' ' '`

helpFunction()
{
   echo "Usage: $0 -d desktop -r release type"
   echo -e "\t-h for help"
   echo -e "\t-d Desktop: ${desktop_list}"
   echo -e "\t-r Release: devel or release"
   exit 1 # Exit script after printing help
}

while getopts "d:r:" opt
do
   case "$opt" in
      'd') export desktop="$OPTARG" ;;
      'r') export release_type="$OPTARG" ;;
      'h') helpFunction ;;
      '?') helpFunction ;;
      *) helpFunction ;;
   esac
done


validate_desktop()
{
  if [ ! -f "${cwd}/packages/${desktop}" ] ; then
    echo "Invalid choice specified"
    echo "Possible choices are:"
    echo $desktop_list
    echo "Usage: ./build.sh mate"
    exit 1
  fi
}

if [ ! -n "$desktop" ]
then
  export desktop="mate"
else
  validate_desktop
fi


if [ ! -n "$release_type" ]
then
  export release_type="devel"
fi

# Source our functions
. functions.sh

workspace
base
packages_software
user
xorg
rc
extra_config
uzip
ramdisk
mfs
boot
image
