#!/usr/bin/env sh

# Source our functions
. functions.sh

clean_workspace
create_workspace
fetch_base
install_base
uzip
ramdisk
boot
image
