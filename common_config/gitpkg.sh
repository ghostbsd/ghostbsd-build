#!/bin/sh

set -e -u

# Installing pc-sysinstall
git_pc_sysinstall()
{
  if [ ! -d "${release}/pc-sysinstall" ]; then
    echo "Downloading pc-sysinstall from GitHub"
    git clone -b locale https://github.com/ghostbsd/pc-sysinstall.git "${release}/pc-sysinstall" >/dev/null 2>&1
    # cp -R /usr/home/ericbsd/projects/ghostbsd/pc-sysinstall "${release}/pc-sysinstall"
  fi

  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing pc-syinstall"
cd /pc-sysinstall
sh install.sh >/dev/null 2>&1
EOF

  chroot "${release}" sh /config.sh
  rm -f "${release}/config.sh"
  rm -rf "${release}/pc-sysinstall"
}

git_gbi()
{
  if [ ! -d "${release}/gbi" ]; then
    echo "Downloading gbi from GitHub"
    # git clone -b ghostbsd-src/issues/105 https://github.com/GhostBSD/gbi.git "${release}/gbi" >/dev/null 2>&1
    cp -R /usr/home/ericbsd/projects/ghostbsd/gbi "${release}/gbi"
  fi

  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing gbi from GitHub"
cd /gbi
python3 setup.py install >/dev/null 2>&1
EOF

  chroot "${release}" sh /config.sh
  rm -f "${release}/config.sh"
  rm -rf "${release}/gbi"
}

git_install_station()
{
  if [ ! -d "${release}/install-station" ]; then
    echo "Downloading install-station from GitHub"
    # git clone https://github.com/GhostBSD/install-station.git "${release}/install-station" >/dev/null 2>&1
    cp -R /usr/home/ericbsd/projects/ghostbsd/install-station "${release}/install-station"
  fi

  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing install-station from GitHub"
cd /install-station
python3 setup.py install >/dev/null 2>&1
EOF

  chroot "${release}" sh /config.sh
  rm -f "${release}/config.sh"
  rm -rf "${release}/install-station"
}

git_setup_station()
{
  if [ ! -d "${release}/setup-station" ]; then
    echo "Downloading setup-station from GitHub"
    # git clone https://github.com/GhostBSD/setup-station.git "${release}/setup-station" >/dev/null 2>&1
    cp -R /usr/home/ericbsd/projects/ghostbsd/setup-station "${release}/setup-station"
  fi

  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing setup-station from GitHub"
cd /setup-station
python3 setup.py install >/dev/null 2>&1
EOF

  chroot "${release}" sh /config.sh
  rm -f "${release}/config.sh"
  rm -rf "${release}/setup-station"
}
