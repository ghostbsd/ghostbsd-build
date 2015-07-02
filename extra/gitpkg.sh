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
  git clone https://github.com/GhostBSD/pcbsd.git ${BASEDIR}/pcbsd >/dev/null 2>&1
fi

if [ ! -d ${BASEDIR}/gbi ]; then
  echo "Downloading gbi from GitHub"
  git clone https://github.com/GhostBSD/gbi.git ${BASEDIR}/gbi >/dev/null 2>&1
fi


cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
echo "installing pc-syinstall"
cd /pcbsd/src-sh/pcbsd-utils/pc-sysinstall
sh install.sh >/dev/null 2>&1
echo "installing gbi"
cd /gbi
sh install.sh >/dev/null 2>&1
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh

# installing PCDM
cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /pcbsd/src-qt5/libpcbsd
/usr/local/lib/qt5/bin/qmake *.pro
make
make install
cd /pcbsd/build-files/ports-overlay/misc/pcbsd-i18n-qt5
/usr/local/lib/qt5/bin/qmake *.pro
make
make install
cd /pcbsd/src-qt5/PCDM
/usr/local/lib/qt5/bin/qmake *.pro
make
make install
EOF

echo "Downloading i18n archive.."
fetch -o /tmp/.pcbsd-i18n.txz http://www.pcbsd.org/i18n/pcbsd-i18n.txz
echo "Extracting i18n files.."
mkdir -p ${BASEDIR}/usr/local/share/pcbsd/i18n
tar xvf /tmp/.pcbsd-i18n.txz -C ${BASEDIR}/usr/local/share/pcbsd/i18n 2>/dev/null >/dev/null
rm /tmp/.pcbsd-i18n.txz

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh

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
make install
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
make install
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/update-station

# # installing Networkmgr
# if [ ! -d ${BASEDIR}/networkmgr ]; then
#   echo "# Downloading netwokmgr from GitHub #"
#   git clone https://github.com/GhostBSD/networkmgr.git ${BASEDIR}/networkmgr >/dev/null 2>&1
# fi

# cat > ${BASEDIR}/config.sh << 'EOF'
# #!/bin/sh
# cd /networkmgr
# make install
# EOF

# chroot ${BASEDIR} sh /config.sh
# rm -f ${BASEDIR}/config.sh
# rm -rf ${BASEDIR}/networkmgr

# installing Station Tweak 
if [ ! -d ${BASEDIR}/station-tweak ]; then
  echo "# Downloading station-tweak from GitHub #"
  git clone https://github.com/GhostBSD/station-tweak.git ${BASEDIR}/station-tweak >/dev/null 2>&1
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /station-tweak
python setup.py build
python setup.py install
EOF

chroot ${BASEDIR} sh /config.sh
cp ${BASEDIR}/station-tweak/station-tweak ${BASEDIR}/usr/local/bin/station-tweak
chmod +x ${BASEDIR}/usr/local/bin/station-tweak
rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/station-tweak
