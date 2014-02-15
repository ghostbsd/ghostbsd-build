#!/bin/sh
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# gnome.sh,v 1.2_1 Monday, January 31 2011 00:49:48 Eric
#

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

cp -f extra/gnome/host1plus.desktop ${BASEDIR}/root/
cp -f extra/gnome/logo_h1p.png ${BASEDIR}/usr/local/share/pixmaps/

cp -f extra/gnome/xinitrc ${BASEDIR}/usr/local/lib/X11/xinit/xinitrc


rm ${BASEDIR}/usr/local/share/applications/libreoffice-draw.desktop
cp -f extra/gnome/libreoffice-draw.desktop ${BASEDIR}/usr/local/share/applications/libreoffice-draw.desktop

# Ghostbsd theme.
cp -prf extra/gnome/themes ${BASEDIR}/usr/local/share/
rm -f ${BASEDIR}/usr/local/share/icons/gnome/icon-theme.cache
tar xfz extra/gnome/icons.tar.gz -C ${BASEDIR}/usr/local/share
cp -prf extra/gnome/gnome ${BASEDIR}/usr/local/share/pixmaps/backgrounds/
cp -f extra/gnome/gnome-bsd.xml ${BASEDIR}/usr/local/share/gnome-background-properties/

#Gconf GhostBSD defaults.
mkdir -p /usr/local/etc/default
rm -rf ${BASEDIR}/usr/local/etc/gconf/gconf.xml.defaults
cp -f extra/gnome/gnome-desktop-settings /usr/local/etc/default/
cp -f extra/gnome/get_settings /usr/local/etc/default/
mkdir -p ${BASEDIR}/usr/local/etc/default
cp -f extra/gnome/gnome-desktop-settings  ${BASEDIR}/usr/local/etc/default
sh /usr/local/etc/default/get_settings
rm -rf /usr/local/etc/default
cp -prf /usr/local/etc/gconf/gconf.xml.defaults ${BASEDIR}/usr/local/etc/gconf
cat extra/gnome/rc.conf.file >> ${BASEDIR}/etc/rc.conf

if [ -f ${BASEDIR}/usr/local/share/applications/gksu.desktop ] ; then
        /usr/bin/sed -i "" "s@/usr/bin/x-terminal-emulator@/usr/local/bin/gnome-terminal@" ${BASEDIR}/usr/local/share/applications/gksu.desktop
fi

if [ -f ${BASEDIR}/usr/local/share/applications/cups.desktop ] ; then
        /usr/bin/sed -i "" "s@htmlview@firefox@" ${BASEDIR}/usr/local/share/applications/cups.desktop
fi

if [ -f ${BASEDIR}/usr/local/share/applications/evince.desktop ] ; then
        /usr/bin/sed -i "" "s@NoDisplay=true@NoDisplay=false@" ${BASEDIR}/usr/local/share/applications/evince.desktop
fi

# Cups adds.
cp -f extra/gnome/devfs.rules ${BASEDIR}/etc/
cat extra/gnome/make.conf >> ${BASEDIR}/etc/make.conf

#add sudo wheel permission
cp extra/gnome/sudoers ${BASEDIR}/usr/local/etc/ 


# To enable USB devices that are plugged in to be read/written
# by operators (i.e. the live user), this is needed:
if [ -z "$(cat ${BASEDIR}/etc/devd.conf| grep ugen[0-9])" ] ; then
    cat extra/gnome/devd.conf.extra >> ${BASEDIR}/etc/devd.conf
fi
if [ -z "$(cat ${BASEDIR}/etc/sysctl.conf| grep vfs.usermount)" ] ; then
    echo "vfs.usermount=1" >> ${BASEDIR}/etc/sysctl.conf
fi

# Set cursor theme instead of default from xorg
if [ -e ${BASEDIR}/usr/local/lib/X11/icons/default ] ; then
rm ${BASEDIR}/usr/local/lib/X11/icons/default 
fi
cd ${BASEDIR}/usr/local/lib/X11/icons
ln -sf $CURSOR_THEME default
cd - 

# Allow GDM auto login:
printf "
auth       required     pam_permit.so
account    required     pam_nologin.so
account    required     pam_unix.so
session    required     pam_permit.so
" > ${BASEDIR}/etc/pam.d/gdm-autologin


# Use a GDM config file which enables auto login as the live user:
#cp -f extra/gnome/custom.conf ${BASEDIR}/usr/local/etc/gdm/custom.conf

# Add bxpkg to the menue
cp -f extra/gnome/bxpkg-${ARCH}.desktop ${BASEDIR}/usr/local/share/applications/bxpkg.desktop
cp -f extra/gnome/m_icon.png ${BASEDIR}/usr/local/share/pixmaps/
cp -f extra/gnome/gnome-applications.menu ${BASEDIR}/usr/local/etc/xdg/menus


set_polkit_and_root_options()
{
###
# enable polkit operations for users in sudo group
###
polkitdir="${BASEDIR}/var/lib/polkit-1/localauthority/10-vendor.d"
if [ ! -d "${polkitdir}" ];
then
    mkdir -p ${polkitdir}
fi

cat > ${polkitdir}/10-live-cd.pkla << EOF
[Live CD user permissions]
Identity=unix-group:wheel
Action=*
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

cat > ${polkitdir}/com.ghostbsd.desktop.pkla << EOF
[Mounting, checking, etc. of internal drives]
Identity=unix-group:wheel
Action=org.freedesktop.udisks.filesystem-*;org.freedesktop.udisks.drive-ata-smar
t*
ResultActive=yes

[Change CPU Frequency scaling]
Identity=unix-group:wheel
Action=org.gnome.cpufreqselector
ResultActive=yes

[Setting the clock]
Identity=unix-group:wheel
Action=org.gnome.clockapplet.mechanism.*
ResultActive=yes

[Adding or modifying users]
Identity=unix-group:wheel
Action=org.freedesktop.systemtoolsbackends.set
ResultActive=yes

[Live CD user permissions]
Identity=unix-group:wheel
Action=*
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
}

set_polkit_and_root_options

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh

if [ -s /usr/local/etc/default/gnome-desktop-settings ]; then
        . /usr/local/etc/default/gnome-desktop-settings
fi

HOME="/home/${USER}"

###
# configure GnuPG if installed
###
GNUPG_CONF='${HOME}/.gnupg/gpg.conf'
KEY_SERVER='hkp://keyserver.noreply.org:80'
if [ ! -f "${GNUPG_CONF}" ]; then
        if which gpg >/dev/null; then
                gpg -k >/dev/null 2>&1
                if [ -f "${GNUPG_CONF}" ]; then
                        sed -ri "" -e 's/^#.*keyserver-options auto-key-retrieve/keyserver-options auto-key-retrieve/' \
                        -e 's/^#.*charset utf-8/charset utf-8/' \
                        -e 's/^keyserver /#keyserver/' "${GNUPG_CONF}"
                        echo "keyserver ${KEY_SERVER}" >> "${GNUPG_CONF}"
                                if which gpg-agent >/dev/null; then
                                        sed -ri "" 's/^#.*use-agent/use-agent/' "${GNUPG_CONF}"
                                fi
                fi
        fi
fi

###
## Make user Desktop dir if doesn't exists
###
if [ ! -d "${HOME}/Desktop" ] ; then
        mkdir -p "${HOME}/Desktop"
fi

if [ "$SMEDIA" = "live" ] ; then
###
## put a GhostBSD-irc icon on the desktop
####
    if [ ! -f "${HOME}/Desktop/ghostbsd-irc.desktop" ] && \
        [ -f /usr/local/share/applications/ghostbsd-irc.desktop ]; then
        cp /usr/local/share/applications/ghostbsd-irc.desktop "${HOME}/Desktop"
        chown ${USER} "${HOME}/Desktop/ghostbsd-irc.desktop"
        chmod 755 "${HOME}/Desktop/ghostbsd-irc.desktop"
    fi

###
## put a installer (GBI icon) on the desktop
####

    if [ ! -f "${HOME}/Desktop/GBI.desktop" ] && \
        [ -f /usr/local/share/applications/GBI.desktop ]; then
        cp /usr/local/share/applications/GBI.desktop "${HOME}/Desktop"
        chown ${USER} "${HOME}/Desktop/GBI.desktop"
        chmod 755 "${HOME}/Desktop/GBI.desktop"
    fi
    
    if [ ! -f "${HOME}/Desktop/host1plus.desktop" ]; then
        cp /root/host1plus.desktop "${HOME}/Desktop"
        chown ${USER} "${HOME}/Desktop/host1plus.desktop"
        chmod 755 "${HOME}/Desktop/host1plus.desktop"
    fi
fi
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh 

###
# Set Linux compatibility and Linux flash player.
###

# add Linux proc for Linux compatibility and Linux flash player.
#if [ -e ${BASEDIR}/usr/local/bin/nspluginwrapper ];then
#cat > ${BASEDIR}/flash.sh << 'EOF'

#/usr/local/bin/nspluginwrapper -v -i /usr/local/lib/npapi/linux-f10-flashplugin/libflashplayer.so
#EOF
#chroot ${BASEDIR} sh /flash.sh
#rm -f ${BASEDIR}/flash.sh
#ln -s ${BASEDIR}/usr/local/lib/browser_plugins/ ${BASEDIR}/usr/local/lib/firefox/plugins
#fi

###
# set homepage as ${DISTRO_URL} in browser
###
set_homepage()
{
case ${launcher} in
        chromium-browser)
                chromium_dir="/usr/local/etc/chromium-browser"
                homepage_ini=`cat ${chromium_dir}/master_preferences | grep homepage | awk '{print $2}'`
                sudo chmod 755 ${chromium_dir}
                sed -i "" "s@${homepage_ini}@\"${DISTRO_URL}\"@" ${chromium_dir}/master_preferences
                sudo chmod 755 ${chromium_dir}
                ;;
        epiphany)
                gconftool-2 -s /apps/epiphany/general/homepage -t string "${DISTRO_URL}"
                ;;
        firefox3)
                firefox_dir="/home/${USER}/.mozilla"
                if [ ! -d "${firefox_dir}" ] ; then
                        mkdir -p ${firefox_dir}/firefox/uwfpw21c.default
                fi
                cat > ${firefox_dir}/firefox/profiles.ini << EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=uwfpw21c.default
EOF

                ;;
        midori)
                midori_dir="/home/${USER}/.config/midori"
                if [ ! -d "${midori_dir}" ] ; then
                        mkdir -p ${midori_dir}
                fi
                        cat > ${midori_dir}/config << EOF
[settings]
default-encoding=UTF-8
last-window-width=1044

last-window-height=768
last-web-search=1
load-on-startup=MIDORI_STARTUP_HOMEPAGE
preferred-encoding=MIDORI_ENCODING_UNICODE
speed-dial-in-new-tabs=false
location-entry-search=http://search.yahoo.com/search?p=
user-agent=Midori/0.2 (X11; Linux; U; en-us) WebKit/531.2+
EOF
echo "homepage=${DISTRO_URL}" >> ${midori_dir}/config
        ;;
esac
}
#set_homepage
