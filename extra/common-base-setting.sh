#!/bin/sh

base_overrides()
{
    cp -af extra/common-base-setting/override/* ${BASEDIR}/
}


patch_etc_files()
{
  cat extra/common-base-setting/patches/boot/loader.conf.extra >> /boot/loader.conf
  cat extra/common-base-setting/patches/etc/profile.extra >> /etc/profile
  cat extra/common-base-setting/patches/etc/devfs.rules.extra >> /etc/devfs.rules
  cat extra/common-base-setting/patches/etc/make.conf.extra >> /etc/make.conf
  cat extra/common-base-setting/patches/etc/rc.conf.extra >> /etc/rc.conf
  cat extra/common-base-setting/patches/etc/devd.conf.extra >> /etc/devd.conf
  cat extra/common-base-setting/patches/etc/sysctl.conf.extra >> /etc/sysctl.conf
}

packages_settings()
{
    #set htmlview alternative to firefox for cups
    if [ -e /usr/local/bin/firefox ] ; then
        update-alternatives --altdir /usr/local/etc/alternatives --install /usr/local/bin/htmlview htmlview /usr/local/bin/firefox 50
    fi
}

# copy files from override to FreeBSD base system
freebsd_overrides
# patch files from etc
patch_etc_files
# apply packages settings
packages_settings

