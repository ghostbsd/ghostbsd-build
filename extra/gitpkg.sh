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
if

if [ ! -d ${BASEDIR}/wallpaper ]; then
  git clone https://github.com/GhostBSD/wallpaper.git ${BASEDIR}/wallpaper
fi

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /wallpaper
sh install.sh
EOF

rm -f ${BASEDIR}/config.sh
rm -rf ${BASEDIR}/wallpaper

# Installer backend.
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

cat > ${BASEDIR}/config.sh << 'EOF'
#!/bin/sh
cd /pcbsd/src-qt4/libpcbsd
qmake-qt4 *.pro
make
make install
cd /pcbsd/src-qt4/PCDM
qmake-qt4 *.pro
make
make install
EOF

chroot ${BASEDIR} sh /config.sh
rm -f ${BASEDIR}/config.sh

rm -rf ${BASEDIR}/pcbsd
rm -rf ${BASEDIR}/gbi

