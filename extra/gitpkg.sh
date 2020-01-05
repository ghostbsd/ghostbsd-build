#!/bin/sh

set -e -u

# Installing pc-sysinstall
git_pc_sysinstall()
{
  if [ ! -d ${release}/pc-sysinstall ]; then
    echo "Downloading pc-sysinstall from GitHub"
    git clone https://github.com/ghostbsd/pc-sysinstall.git ${release}/pc-sysinstall >/dev/null 2>&1
    # cp -R /usr/home/ericbsd/projects/ghostbsd/pc-sysinstall ${release}/pc-sysinstall
  fi

  cat > ${release}/config.sh << 'EOF'
#!/bin/sh
echo "installing pc-syinstall"
cd /pc-sysinstall
sh install.sh >/dev/null 2>&1
EOF

  chroot ${release} sh /config.sh
  rm -f ${release}/config.sh
  rm -rf ${release}/pc-sysinstall
}

git_gbi()
{
  if [ ! -d ${release}/pc-sysinstall ]; then
    echo "Downloading gbi from GitHub"
    git clone https://github.com/GhostBSD/gbi.git ${release}/gbi >/dev/null 2>&1
    # cp -R /usr/home/ericbsd/projects/ghostbsd/gbi ${release}/gbi
  fi

  cat > ${release}/config.sh << 'EOF'
#!/bin/sh
echo "installing gbi from git"
cd /gbi
/usr/local/bin/python3.7 setup.py install >/dev/null 2>&1
EOF

  chroot ${release} sh /config.sh
  rm -f ${release}/config.sh
  rm -rf ${release}/gbi
}

git_xfce_settings()
{
  if [ ! -d ${release}/pc-sysinstall ]; then
    echo "Downloading gbi from GitHub"
    git clone https://github.com/GhostBSD/ghostbsd-xfce-settings.git ${release}/ghostbsd-xfce-settings >/dev/null 2>&1
  fi

  cat > ${release}/config.sh << 'EOF'
#!/bin/sh
echo "installing ghostbsd-xfce-settings from git"
cd /ghostbsd-xfce-settings
cp -R etc/xdg/* /usr/local/etc/xdg/
EOF

  chroot ${release} sh /config.sh
  rm -f ${release}/config.sh
  rm -rf ${release}/ghostbsd-xfce-setting
}

