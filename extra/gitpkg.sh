#!/bin/sh

set -e -u

if [ -z "${LOGFILE:-}" ]; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

if [ ! -f "/usr/local/bin/git" ]; then
  echo "Install Git to fetch pkg from GitHub"
  exit 1
fi

# Installing pc-sysinstall and ghostbsd installer

if [ ! -d ${BASEDIR}/pc-sysinstall ]; then
  echo "Downloading pcbsd tools from GitHub"
  git clone https://github.com/GhostBSD/pc-sysinstall.git ${BASEDIR}/pc-sysinstall >/dev/null 2>&1
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
echo "installing pc-syinstall"
cd /pc-sysinstall
sh install.sh >/dev/null 2>&1
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh

rm -rf ${BASEDIR}/pc-sysinstall

# # installing PCDM
# cat > ${BASEDIR}/config.sh << 'EOF'
# #!/bin/sh
# echo "installing libpcbsd"
# cd /pcbsd/src-qt5/libpcbsd
# /usr/local/lib/qt5/bin/qmake *.pro
# make >/dev/null 2>&1
# make install >/dev/null 2>&1
# echo "installing pcbsd-i18n-qt5"
# cd /pcbsd/build-files/ports-overlay/misc/pcbsd-i18n-qt5
# /usr/local/lib/qt5/bin/qmake *.pro
# make >/dev/null 2>&1
# make install >/dev/null 2>&1
# echo "installing PCDM"
# cd /pcbsd/src-qt5/PCDM
# /usr/local/lib/qt5/bin/qmake *.pro
# make> /dev/null 2>&1
# make install >/dev/null 2>&1
# EOF

# echo "Downloading i18n archive.."
# fetch -o /tmp/.pcbsd-i18n.txz http://www.pcbsd.org/i18n/pcbsd-i18n.txz >/dev/null 2>&1
# echo "Extracting i18n files.."
# mkdir -p ${BASEDIR}/usr/local/share/pcbsd/i18n
# tar xvf /tmp/.pcbsd-i18n.txz -C ${BASEDIR}/usr/local/share/pcbsd/i18n 2>/dev/null >/dev/null
# rm /tmp/.pcbsd-i18n.txz

# chroot ${BASEDIR} sh /config.sh
# rm -f ${BASEDIR}/config.sh
