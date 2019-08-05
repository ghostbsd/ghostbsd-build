#!/bin/sh

set -e -u

# Installing pc-sysinstall
git_pc_sysinstall()
{
  if [ ! -d ${release}/pc-sysinstall ]; then
    echo "Downloading pc-sysinstall from GitHub"
    git clone https://github.com/trueos/pc-sysinstall.git ${release}/pc-sysinstall >/dev/null 2>&1
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
  fi

  cat > ${release}/config.sh << 'EOF'
#!/bin/sh
echo "installing gbi from git"
cd /gbi
python3.6 setup.py install >/dev/null 2>&1
EOF

  chroot ${release} sh /config.sh
  rm -f ${release}/config.sh
  rm -rf ${release}/gbi
}
