#!/bin/sh

if [ -f /usr/local/etc/default/distro ] ; then
. /usr/local/etc/default/distro
fi

# add to webcamd group desktopbsd user
pw groupmod webcamd -m ${DISTRO_LIVEUSER}

# enable webcamd in rc.conf
echo 'webcamd_enable="YES"' >> /etc/rc.conf

# load cuse4bsd from loader.conf
grep -q "cuse_load" /boot/loader.conf
if [ $? -ne 0 ]; then
    echo 'cuse_load="YES"' >> /boot/loader.conf
fi

# load cuse4bsd from grub.cfg
grep -q "cuse" /boot/grub/grub.cfg
if [ $? -ne 0 ]; then
sed -i '' '/set kFreeBSD.kern.vty=vt/a\
\  kfreebsd_module_elf /boot/modules/cuse.ko\
' /boot/grub/grub.cfg
fi