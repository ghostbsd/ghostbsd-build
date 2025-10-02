#!/bin/sh

set -e -u

# -------- Logging (color-ready, default OFF) --------
# Toggle: 0 = plain (default), 1 = color on
# Honors NO_COLOR (https://no-color.org) and FORCE_COLOR.
: "${LOG_COLOR:=0}"
[ -n "${NO_COLOR:-}" ] && LOG_COLOR=0
[ -n "${FORCE_COLOR:-}" ] && LOG_COLOR=1

# ANSI color codes
RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; CYAN="\033[36m"; RESET="\033[0m"

log() {
    # plain if disabled or not a TTY
    if [ "$LOG_COLOR" -ne 1 ] || [ ! -t 1 ]; then
        echo "$*"
        return
    fi

    _c="$CYAN"
    case "$1" in
        ERROR:*|Error:*|error:*)    _c="$RED" ;;
        WARNING:*|Warning:*|warn:*) _c="$YELLOW" ;;
        SUCCESS:*|Success:*)        _c="$GREEN" ;;
        INFO:*|Info:*)              _c="$BLUE" ;;
    esac

    # shellcheck disable=SC2059
    printf "%b\n" "${_c}$*${RESET}"
}

# Helper function to check network connectivity
check_network() {
    log "INFO: Checking network connectivity to GitHub..."
    if ping -c 1 -t 5 github.com >/dev/null 2>&1; then
        log "SUCCESS: Network connectivity confirmed"
        return 0
    else
        log "WARNING: Cannot reach github.com"
        return 1
    fi
}

# Helper function for git clone with timeout
git_clone_with_timeout() {
    local repo_url="$1"
    local dest_path="$2"
    local timeout="${3:-60}"  # default 60 seconds
    local branch="${4:-}"
    
    local git_cmd="git clone"
    [ -n "$branch" ] && git_cmd="$git_cmd -b $branch"
    git_cmd="$git_cmd $repo_url $dest_path"
    
    log "INFO: Cloning with ${timeout}s timeout..."
    
    # Run git clone with timeout
    if timeout "$timeout" sh -c "$git_cmd" 2>&1 | while IFS= read -r line; do
        # Show progress for verbose output
        case "$line" in
            *"Cloning into"*|*"remote: Counting"*|*"Receiving objects"*)
                echo "  $line"
                ;;
            *"error"*|*"fatal"*|*"Error"*|*"Fatal"*)
                log "ERROR: $line"
                ;;
        esac
    done; then
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log "ERROR: Git clone timed out after ${timeout}s"
        else
            log "ERROR: Git clone failed with exit code $exit_code"
        fi
        return 1
    fi
}

# Enhanced pc-sysinstall installation with proper git clone
git_pc_sysinstall()
{
  if [ ! -d "${release}/pc-sysinstall" ]; then
    log "INFO: Downloading pc-sysinstall from GitHub"

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "ERROR: git not found, cannot clone pc-sysinstall"
      log "INFO: Installing git..."
      pkg install -y git || {
        log "ERROR: Failed to install git, skipping pc-sysinstall"
        return 0
      }
    fi

    # Check network connectivity
    if ! check_network; then
      log "WARNING: No network connectivity, checking for local copy"
      if [ -d "/usr/home/ericbsd/projects/ghostbsd/pc-sysinstall" ]; then
        log "INFO: Using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/pc-sysinstall "${release}/pc-sysinstall"
      else
        log "WARNING: Cannot find local copy, skipping pc-sysinstall"
        return 0
      fi
    else
      # Try git clone with timeout and fallback to local copy
      if git_clone_with_timeout "https://github.com/ghostbsd/pc-sysinstall.git" \
                                  "${release}/pc-sysinstall" 60 "master"; then
        log "SUCCESS: Successfully cloned pc-sysinstall from GitHub"
      elif [ -d "/usr/home/ericbsd/projects/ghostbsd/pc-sysinstall" ]; then
        log "WARNING: Git clone failed, using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/pc-sysinstall "${release}/pc-sysinstall"
      else
        log "WARNING: Cannot clone or find pc-sysinstall, skipping"
        return 0
      fi
    fi
  fi

  log "INFO: Installing pc-sysinstall"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing pc-sysinstall"
cd /pc-sysinstall
sh install.sh >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "SUCCESS: pc-sysinstall installed successfully"
  else
    log "WARNING: pc-sysinstall installation failed, continuing anyway"
  fi

  rm -f "${release}/config.sh"
  rm -rf "${release}/pc-sysinstall"
}

git_gbi()
{
  if [ ! -d "${release}/gbi" ]; then
    log "INFO: Downloading gbi from GitHub"

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "WARNING: git not found, skipping gbi"
      return 0
    fi

    # Check network connectivity
    if ! check_network; then
      log "WARNING: No network connectivity, checking for local copy"
      if [ -d "/usr/home/ericbsd/projects/ghostbsd/gbi" ]; then
        log "INFO: Using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/gbi "${release}/gbi"
      else
        log "WARNING: Cannot find local copy, skipping gbi"
        return 0
      fi
    else
      # Try git clone with timeout and fallback to local copy
      if git_clone_with_timeout "https://github.com/ghostbsd/gbi.git" \
                                  "${release}/gbi" 60; then
        log "SUCCESS: Successfully cloned gbi from GitHub"
      elif [ -d "/usr/home/ericbsd/projects/ghostbsd/gbi" ]; then
        log "WARNING: Git clone failed, using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/gbi "${release}/gbi"
      else
        log "WARNING: Cannot clone or find gbi, skipping"
        return 0
      fi
    fi
  fi

  log "INFO: Installing gbi"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing gbi from GitHub"
cd /gbi
python3 setup.py install >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "SUCCESS: gbi installed successfully"
  else
    log "WARNING: gbi installation failed, continuing anyway"
  fi

  rm -f "${release}/config.sh"
  rm -rf "${release}/gbi"
}

git_install_station()
 {
  if [ ! -d "${release}/install-station" ]; then
    log "INFO: Downloading install-station from GitHub"

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "WARNING: git not found, skipping install-station"
      return 0
    fi

    # Check network connectivity
    if ! check_network; then
      log "WARNING: No network connectivity, checking for local copy"
      if [ -d "/usr/home/ericbsd/projects/ghostbsd/install-station" ]; then
        log "INFO: Using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/install-station "${release}/install-station"
      else
        log "WARNING: Cannot find local copy, skipping install-station"
        return 0
      fi
    else
      # Try git clone with timeout and fallback to local copy
      if git_clone_with_timeout "https://github.com/GhostBSD/install-station.git" \
                                  "${release}/install-station" 60; then
        log "SUCCESS: Successfully cloned install-station from GitHub"
      elif [ -d "/usr/home/ericbsd/projects/ghostbsd/install-station" ]; then
        log "WARNING: Git clone failed, using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/install-station "${release}/install-station"
      else
        log "WARNING: Cannot clone or find install-station, skipping"
        return 0
      fi
    fi
  fi

  log "INFO: Installing install-station"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing install-station from GitHub"
cd /install-station
python3 setup.py install >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "SUCCESS: install-station installed successfully"
  else
    log "WARNING: install-station installation failed, continuing anyway"
  fi

  rm -f "${release}/config.sh"
  rm -rf "${release}/install-station"
}

git_setup_station()
{
  if [ ! -d "${release}/setup-station" ]; then
    log "INFO: Downloading setup-station from GitHub"

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
      log "WARNING: git not found, skipping setup-station"
      return 0
    fi

    # Check network connectivity
    if ! check_network; then
      log "WARNING: No network connectivity, checking for local copy"
      if [ -d "/usr/home/ericbsd/projects/ghostbsd/setup-station" ]; then
        log "INFO: Using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/setup-station "${release}/setup-station"
      else
        log "WARNING: Cannot find local copy, skipping setup-station"
        return 0
      fi
    else
      # Try git clone with timeout and fallback to local copy
      if git_clone_with_timeout "https://github.com/GhostBSD/setup-station.git" \
                                  "${release}/setup-station" 60; then
        log "SUCCESS: Successfully cloned setup-station from GitHub"
      elif [ -d "/usr/home/ericbsd/projects/ghostbsd/setup-station" ]; then
        log "WARNING: Git clone failed, using local copy"
        cp -R /usr/home/ericbsd/projects/ghostbsd/setup-station "${release}/setup-station"
      else
        log "WARNING: Cannot clone or find setup-station, skipping"
        return 0
      fi
    fi
  fi

  log "INFO: Installing setup-station"
  cat > "${release}/config.sh" << 'EOF'
#!/bin/sh
set -e -u
echo "installing setup-station from GitHub"
cd /setup-station
python3 setup.py install >/dev/null 2>&1
EOF

  if chroot "${release}" sh /config.sh; then
    log "SUCCESS: setup-station installed successfully"
  else
    log "WARNING: setup-station installation failed, continuing anyway"
  fi

  rm -f "${release}/config.sh"
  rm -rf "${release}/setup-station"
}
