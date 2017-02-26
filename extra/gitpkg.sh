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

