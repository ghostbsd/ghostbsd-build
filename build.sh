#!/usr/bin/env sh

# Source our functions
. functions.sh

validate_user

case $stage in
  'stage1')
    echo "##### Starting Stage 1 #####" 1>&2
    determine_desktop
#    validate_user
    validate_kernrel
    workspace
    base
    packages_software
    echo "##### Completed Stage 1 #####" 1>&2  
    exit 1
    ;;
  'stage2')
    echo "##### Starting Stage 2 #####" 1>&2
    user
    xorg
    rc
    extra_config
    uzip
    ramdisk
    mfs
    boot
    image
    echo "##### Completed Stage 2 #####" 1>&2  
    exit 1
    ;;
  *)
   echo "##### Starting all stages #####" 1>&2
    determine_desktop
#    validate_user
    validate_kernrel
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
    echo "##### Completed all stages #####" 1>&2
    ;;
esac
