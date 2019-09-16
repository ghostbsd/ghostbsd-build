#!/usr/bin/env sh

# Source our functions
. functions.sh

case $stage in
  'stage1')
    echo "Starting Stage 1" 1>&2
    determine_desktop
    validate_user
    validate_kernrel
    workspace
    base
    packages_software
    ;;
  'stage2')
    echo "Starting Stage 2" 1>&2
    user
    xorg
    rc
    extra_config
    uzip
    ramdisk
    mfs
    mfs
    boot
    image
    ;;
  *)
   echo "Starting all stages"
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
