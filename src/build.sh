#!/usr/bin/env sh

# Source our functions
. functions.sh

clean_workspace
create_workspace
fetch_base
install_base
install_overlay
install_packages
add_user
uzip
ramdisk
boot
image
