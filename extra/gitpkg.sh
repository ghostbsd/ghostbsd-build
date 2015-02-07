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
      
# installing GhostBSD wallpapers
if [ ! -d ${BASEDIR}/wallpaper ]; then
  git clone https://github.com/GhostBSD/wallpaper.git ${BASEDIR}/wallpaper
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /wallpaper
sh install.sh
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/wallpaper

# Installing pc-sysinstall and ghostbsd installer
if [ ! -d ${BASEDIR}/pcbsd ]; then
  git clone https://github.com/pcbsd/pcbsd.git ${BASEDIR}/pcbsd
fi

if [ ! -d ${BASEDIR}/gbi ]; then
  git clone https://github.com/GhostBSD/gbi.git ${BASEDIR}/gbi
fi


cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /pcbsd/src-sh/pcbsd-utils/pc-sysinstall
sh install.sh
cd /gbi
sh install.sh
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
cd /pcbsd/src-qt5/PCDM
/usr/local/lib/qt5/bin/qmake *.pro
make
make install
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh

rm -rf ${BASEDIR}/pcbsd
rm -rf ${BASEDIR}/gbi

# installing GhostBSD wallpapers
if [ ! -d ${BASEDIR}/operator ]; then
  git clone https://github.com/GhostBSD/operator.git ${BASEDIR}/operator
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
  git clone https://github.com/GhostBSD/update-station.git ${BASEDIR}/update-station
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /update-station
make install
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/update-station

# installing GhostBSD wallpapers
if [ ! -d ${BASEDIR}/networkmgr ]; then
  git clone https://github.com/GhostBSD/networkmgr.git ${BASEDIR}/networkmgr
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /networkmgr
make install
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/networkmgr
