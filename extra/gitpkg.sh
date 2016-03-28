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
if [ ! -d ${BASEDIR}/pcbsd ]; then
  echo "Downloading pcbsd tools from GitHub"
#  git clone https://github.com/GhostBSD/pcbsd.git ${BASEDIR}/pcbsd >/dev/null 2>&1
  fetch https://github.com/GhostBSD/pcbsd/archive/master.zip -o ${BASEDIR}/master.zip >/dev/null 2>&1
  unzip ${BASEDIR}/master.zip -d ${BASEDIR} >/dev/null 2>&1
  mv ${BASEDIR}/pcbsd-master ${BASEDIR}/pcbsd
  rm ${BASEDIR}/master.zip
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
echo "installing pc-syinstall"
cd /pcbsd/src-sh/pcbsd-utils/pc-sysinstall
sh install.sh >/dev/null 2>&1
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh

if [ ! -d ${BASEDIR}/gbi ]; then
  echo "Downloading GBI from GitHub"
  fetch https://github.com/GhostBSD/gbi/archive/master.zip -o ${BASEDIR}/master.zip >/dev/null 2>&1
  unzip ${BASEDIR}/master.zip -d ${BASEDIR} >/dev/null 2>&1
  mv ${BASEDIR}/gbi-master ${BASEDIR}/gbi
  rm ${BASEDIR}/master.zip
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
echo "installing gbi"
cd /gbi
python setup.py install >/dev/null 2>&1
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh


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

rm -rf ${BASEDIR}/pcbsd
rm -rf ${BASEDIR}/gbi

# installing GhostBSD wallpapers
if [ ! -d ${BASEDIR}/operator ]; then
  echo "# Downloading operator from GitHub #"
  git clone https://github.com/GhostBSD/operator.git ${BASEDIR}/operator >/dev/null 2>&1
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /operator
make install >/dev/null 2>&1
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/operator

# installing GhostBSD wallpapers
if [ ! -d ${BASEDIR}/update-station ]; then
  echo "# Downloading uodate-station from GitHub #"
  git clone https://github.com/GhostBSD/update-station.git ${BASEDIR}/update-station >/dev/null 2>&1
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /update-station
python setup.py install >/dev/null 2>&1
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/update-station
