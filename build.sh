#!/usr/bin/env sh

# Source our functions
. functions.sh

determine_desktop
validate_user
validate_kernrel

while :
do
  case $stage in
    'stage1')
      echo "***** Starting Stage 1 *****" 1>&2
      workspace
      base
      packages_software
      echo "***** Completed Stage 1 *****" 1>&2
      break  
      ;;
    'stage2')
      echo "***** Starting Stage 2 *****" 1>&2
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
      echo "***** Completed Stage 2 *****" 1>&2  
      break
      ;;
    *)
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
      ;;
  esac
done
