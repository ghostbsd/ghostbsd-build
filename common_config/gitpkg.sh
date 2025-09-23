#!/bin/sh

set -e -u

log() {
    echo "$(date '+%H:%M:%S') [GITPKG] $*"
}

# Enhanced pc-sysinstall installation with proper git clone
git_pc_sysinstall()
{
  if [ ! -d "${release}/pc-sysinstall" ]; then
    log "Downloading pc-sysinstall from GitHub"
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "ERROR: git not found, cannot clone pc-sysinstall"
      log "Installing git..."
      pkg install -y git || {
        log "ERROR: Failed to install git, skipping pc-sysinstall"
        return 0
      }
    fi
    
    # Try git clone with fallback to local copy
    if git clone -b master https://github.com/ghostbsd/pc-sysinstall.git "${release}/pc-sysinstall" >/dev/null 2>&1; then
      log "Successfully cloned pc-sysinstall from GitHub"
    elif [ -d "/usr/home/ericbsd/projects/ghostbsd/pc-sysinstall" ]; then
      log "Git clone failed, using local copy"
      cp -R /usr/home/ericbsd/projects/ghostbsd/pc-sysinstall "${release}/pc-sysinstall"
    else
      log "WARNING: Cannot clone or find pc-sysinstall, skipping"
      return 0
    fi
  fi

  log "Installing pc-sysinstall"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing pc-sysinstall"
cd /pc-sysinstall
sh install.sh >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "pc-sysinstall installed successfully"
  else
    log "WARNING: pc-sysinstall installation failed, continuing anyway"
  fi
  
  rm -f "${release}/config.sh"
  rm -rf "${release}/pc-sysinstall"
}

git_gbi()
{
  if [ ! -d "${release}/gbi" ]; then
    log "Downloading gbi from GitHub"
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "WARNING: git not found, skipping gbi"
      return 0
    fi
    
    # Try git clone with fallback to local copy
    if git clone -b main https://github.com/GhostBSD/gbi.git "${release}/gbi" >/dev/null 2>&1; then
      log "Successfully cloned gbi from GitHub"
    elif [ -d "/usr/home/ericbsd/projects/ghostbsd/gbi" ]; then
      log "Git clone failed, using local copy"
      cp -R /usr/home/ericbsd/projects/ghostbsd/gbi "${release}/gbi"
    else
      log "WARNING: Cannot clone or find gbi, skipping"
      return 0
    fi
  fi

  log "Installing gbi"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing gbi from GitHub"
cd /gbi
python3 setup.py install >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "gbi installed successfully"
  else
    log "WARNING: gbi installation failed, continuing anyway"
  fi
  
  rm -f "${release}/config.sh"
  rm -rf "${release}/gbi"
}

git_install_station()
{
  if [ ! -d "${release}/install-station" ]; then
    log "Downloading install-station from GitHub"
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "WARNING: git not found, skipping install-station"
      return 0
    fi
    
    # Try git clone with fallback to local copy
    if git clone https://github.com/GhostBSD/install-station.git "${release}/install-station" >/dev/null 2>&1; then
      log "Successfully cloned install-station from GitHub"
    elif [ -d "/usr/home/ericbsd/projects/ghostbsd/install-station" ]; then
      log "Git clone failed, using local copy"
      cp -R /usr/home/ericbsd/projects/ghostbsd/install-station "${release}/install-station"
    else
      log "WARNING: Cannot clone or find install-station, skipping"
      return 0
    fi
  fi

  log "Installing install-station"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing install-station from GitHub"
cd /install-station
python3 setup.py install >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "install-station installed successfully"
  else
    log "WARNING: install-station installation failed, continuing anyway"
  fi
  
  rm -f "${release}/config.sh"
  rm -rf "${release}/install-station"
}

git_setup_station()
{
  if [ ! -d "${release}/setup-station" ]; then
    log "Downloading setup-station from GitHub"
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "WARNING: git not found, skipping setup-station"
      return 0
    fi
    
    # Try git clone with fallback to local copy
    if git clone https://github.com/GhostBSD/setup-station.git "${release}/setup-station" >/dev/null 2>&1; then
      log "Successfully cloned setup-station from GitHub"
    elif [ -d "/usr/home/ericbsd/projects/ghostbsd/setup-station" ]; then
      log "Git clone failed, using local copy"
      cp -R /usr/home/ericbsd/projects/ghostbsd/setup-station "${release}/setup-station"
    else
      log "WARNING: Cannot clone or find setup-station, skipping"
      return 0
    fi
  fi

  log "Installing setup-station"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing setup-station from GitHub"
cd /setup-station
python3 setup.py install >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "setup-station installed successfully"
  else
    log "WARNING: setup-station installation failed, continuing anyway"
  fi
  
  rm -f "${release}/config.sh"
  rm -rf "${release}/setup-station"
}
