#!/usr/bin/env sh

set -e -u

cwd="$(realpath)"
export cwd

# ZFS Control Configuration
export zfs_control="${zfs_control:-auto}"  # off, auto, conservative, aggressive, restore
export ARC_WAS_TUNED=false  # Initialize to prevent cleanup errors

# Enhanced logging function
log() {
    echo "$(date '+%H:%M:%S') [BUILD] $*"
}

error_exit() {
    log "ERROR: $*"
    exit 1
}

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Use find to locate base files and extract filenames directly, converting newlines to spaces
desktop_list=$(find packages -type f ! -name '*base*' ! -name '*common*' ! -name '*drivers*' -exec basename {} \; | sort -u | tr '\n' ' ')

# Find all files in the desktop_config directory
desktop_config_list=$(find desktop_config -type f)

help_function()
{
  printf "Usage: %s -d desktop -b build_type [-z zfs_control]\n" "$0"
  printf "\t-h for help\n"
  printf "\t-d Desktop: %s\n" "${desktop_list}"
  printf "\t-b Build type: unstable, testing, or release\n"
  printf "\t-z ZFS control: off, auto, conservative, aggressive, restore\n"
  printf "\t-t Test: FreeBSD os packages\n"
  printf "\nZFS Control Options:\n"
  printf "\t off          - Never modify host ZFS ARC settings (safest)\n"
  printf "\t auto         - Only tune if current ARC significantly exceeds build needs (default)\n"
  printf "\t conservative - Only tune if ARC is using >60%% of system RAM\n"
  printf "\t aggressive   - Always apply build-optimized settings\n"
  printf "\t restore      - Same as aggressive but explicitly shows restore intent\n"
  printf "\nAll modes except 'off' will restore original settings after build completion.\n"
   exit 1 # Exit script after printing help
}

# Set mate and release to be default
export desktop="mate"
export build_type="release"

while getopts "d:b:z:th" opt
do
   case "$opt" in
      'd') export desktop="$OPTARG" ;;
      'b') export build_type="$OPTARG" ;;
      'z') export zfs_control="$OPTARG" ;;
      't') export desktop="test" ; build_type="test";;
      'h') help_function ;;
      '?') help_function ;;
      *) help_function ;;
   esac
done

# Validate zfs_control option
case "$zfs_control" in
    "off"|"auto"|"conservative"|"aggressive"|"restore") ;;
    *) 
        printf "Invalid ZFS control option: %s\n" "$zfs_control"
        printf "Valid options: off, auto, conservative, aggressive, restore\n"
        exit 1
        ;;
esac

if [ "${build_type}" = "testing" ] ; then
  PKG_CONF="GhostBSD_Testing"
elif [ "${build_type}" = "release" ] ; then
  PKG_CONF="GhostBSD"
elif [ "${build_type}" = "unstable" ] ; then
  PKG_CONF="GhostBSD_Unstable"
else
  printf "\t-b Build type: unstable, testing, or release\n"
  exit 1
fi

# validate desktop packages
if [ ! -f "${cwd}/packages/${desktop}" ] ; then
  echo "The packages/${desktop} file does not exist."
  echo "Please create a package file named '${desktop}'and place it under packages/."
  echo "Or use a valid desktop below:"
  echo "$desktop_list"
  echo "Usage: ./build.sh -d desktop"
  exit 1
fi

# validate desktop
if [ ! -f "${cwd}/desktop_config/${desktop}.sh" ] ; then
  echo "The desktop_config/${desktop}.sh file does not exist."
  echo "Please create a config file named '${desktop}.sh' like these config:"
  echo "$desktop_config_list"
  exit 1
fi

if [ "${desktop}" != "mate" ] ; then
  DESKTOP=$(echo "${desktop}" | tr '[:lower:]' '[:upper:]')
  community="-${DESKTOP}"
else
  community=""
fi

workdir="/usr/local"
livecd="${workdir}/ghostbsd-build"
base="${livecd}/base"
iso="${livecd}/iso"
packages_storage="${livecd}/packages"
release="${livecd}/release"
export release
cd_root="${livecd}/cd_root"
live_user="ghostbsd"
export live_user

time_stamp=""
release_stamp=""
label="GhostBSD"

# ZFS ARC Management Functions
zfs_arc_save() {
    if ! kldstat | grep -q zfs; then
        log "ZFS not loaded, skipping ARC management"
        return 0
    fi
    
    # Save current ARC settings
    original_arc_max=$(sysctl -n vfs.zfs.arc_max 2>/dev/null || echo "0")
    original_arc_min=$(sysctl -n vfs.zfs.arc_min 2>/dev/null || echo "0")
    
    log "Current ARC settings: max=${original_arc_max}, min=${original_arc_min}"
    
    # Save to temp files for restoration
    echo "$original_arc_max" > /tmp/ghostbsd_build_arc_max
    echo "$original_arc_min" > /tmp/ghostbsd_build_arc_min
    
    export SAVED_ARC_SETTINGS=true
}

zfs_arc_analyze_and_tune() {
    if [ "$zfs_control" = "off" ]; then
        log "ZFS control disabled, leaving host ARC unchanged"
        return 0
    fi
    
    if ! kldstat | grep -q zfs; then
        log "ZFS not detected"
        return 0
    fi
    
    # Calculate optimal build settings
    realmem=$(sysctl -n hw.realmem)
    realmem_gb=$((realmem / 1024 / 1024 / 1024))
    current_arc_max=$(sysctl -n vfs.zfs.arc_max 2>/dev/null || echo "0")
    current_arc_max_gb=$((current_arc_max / 1024 / 1024 / 1024))
    
    # Calculate build-optimized ARC (30% of RAM, leaves more for build processes)
    build_arc_max=$((realmem * 30 / 100))
    build_arc_max_gb=$((build_arc_max / 1024 / 1024 / 1024))
    
    log "Memory analysis: ${realmem_gb}GB total, current ARC: ${current_arc_max_gb}GB, optimal build ARC: ${build_arc_max_gb}GB"
    
    # Decision logic based on zfs_control setting
    should_tune=false
    case "$zfs_control" in
        "auto")
            # Auto: tune if current ARC is significantly higher than build optimal
            if [ $current_arc_max_gb -gt $((build_arc_max_gb + 2)) ]; then
                should_tune=true
                log "Auto mode: Current ARC (${current_arc_max_gb}GB) significantly exceeds build optimal (${build_arc_max_gb}GB)"
            else
                log "Auto mode: Current ARC settings appear suitable for build"
            fi
            ;;
        "conservative")
            # Conservative: only tune if ARC is using >60% of RAM
            arc_percentage=$((current_arc_max_gb * 100 / realmem_gb))
            if [ $arc_percentage -gt 60 ]; then
                should_tune=true
                log "Conservative mode: Current ARC using ${arc_percentage}% of RAM, tuning recommended"
            else
                log "Conservative mode: Current ARC usage (${arc_percentage}%) is acceptable"
            fi
            ;;
        "aggressive"|"restore")
            # Always tune for optimal build performance
            should_tune=true
            log "${zfs_control} mode: Applying build-optimized ARC settings"
            ;;
    esac
    
    if [ "$should_tune" = "true" ]; then
        log "Applying build-optimized ZFS ARC settings..."
        sysctl vfs.zfs.arc_max=$build_arc_max >/dev/null 2>&1 || true
        log "Set ARC max to ${build_arc_max_gb}GB for build optimization"
        export ARC_WAS_TUNED=true
    else
        log "Keeping existing ZFS ARC settings"
        export ARC_WAS_TUNED=false
    fi
}

zfs_arc_restore() {
    if [ "$zfs_control" = "off" ] || [ "$ARC_WAS_TUNED" != "true" ]; then
        return 0
    fi
    
    if [ ! -f /tmp/ghostbsd_build_arc_max ]; then
        log "Warning: No saved ARC settings found for restoration"
        return 0
    fi
    
    original_arc_max=$(cat /tmp/ghostbsd_build_arc_max)
    original_arc_min=$(cat /tmp/ghostbsd_build_arc_min)
    
    if [ "$original_arc_max" != "0" ]; then
        log "Restoring original ZFS ARC settings..."
        # shellcheck disable=SC2086
        sysctl vfs.zfs.arc_max=$original_arc_max >/dev/null 2>&1 || true
        if [ "$original_arc_min" != "0" ]; then
            # shellcheck disable=SC2086
            sysctl vfs.zfs.arc_min=$original_arc_min >/dev/null 2>&1 || true
        fi
        
        restored_max_gb=$((original_arc_max / 1024 / 1024 / 1024))
        log "Restored ARC max to ${restored_max_gb}GB"
    fi
    
    # Clean up temp files
    rm -f /tmp/ghostbsd_build_arc_max /tmp/ghostbsd_build_arc_min
}

# Cleanup function
cleanup_and_restore() {
    log "Performing cleanup and restoration..."
    zfs_arc_restore
}

# Trap to ensure restoration on exit/error
trap cleanup_and_restore EXIT INT TERM

# Enhanced workspace function with ZFS control and 8GB minimum requirement
workspace()
{
  log "=== Enhanced Workspace Setup with ZFS Control ==="
  log "ZFS control mode: ${zfs_control}"
  
  # Save current ARC settings first
  zfs_arc_save
  
  # Pre-build environment analysis
  log "Analyzing build environment..."
  
  # 1. Memory Analysis - Updated for 8GB minimum
  realmem=$(sysctl -n hw.realmem)
  realmem_gb=$((realmem / 1024 / 1024 / 1024))
  log "Available memory: ${realmem_gb}GB"
  
  if [ $realmem_gb -lt 8 ]; then
    error_exit "GhostBSD build requires at least 8GB RAM. Detected: ${realmem_gb}GB. Please use a system with more memory."
  elif [ $realmem_gb -lt 12 ]; then
    log "WARNING: 8-12GB RAM detected. Build will work but may experience memory pressure."
    log "Consider using a system with 16GB+ RAM for optimal build performance."
  fi
  
  # 2. Disk Space Analysis - Updated for larger requirements
  log "Analyzing disk space..."
  workdir_avail=$(df /usr/local | tail -1 | awk '{print $4}')
  workdir_avail_gb=$((workdir_avail / 1024 / 1024))
  log "Available space in /usr/local: ${workdir_avail_gb}GB"
  
  if [ $workdir_avail_gb -lt 20 ]; then
    error_exit "Insufficient disk space. Need at least 20GB free in /usr/local for 8GB minimum builds, have ${workdir_avail_gb}GB"
  fi
  
  # 3. Check for previous failed builds
  if [ -d "${livecd}" ]; then
    log "Found previous build directory, analyzing..."
    if [ -f "${livecd}/cd_root/data/system.img" ]; then
      old_img_size=$(stat -f %z "${livecd}/cd_root/data/system.img" 2>/dev/null || echo 0)
      old_img_size_mb=$((old_img_size / 1024 / 1024))
      log "Previous system.img size: ${old_img_size_mb}MB"
      if [ $old_img_size_mb -lt 100 ]; then
        log "Previous system.img appears truncated, cleaning up"
      fi
    fi
  fi
  
  # 4. ZFS ARC tuning with user control
  zfs_arc_analyze_and_tune
  
  # Unmount any existing mounts and clean up
  log "Cleaning up previous build artifacts..."
  umount ${packages_storage} >/dev/null 2>/dev/null || true
  umount ${release}/dev >/dev/null 2>/dev/null || true
  zpool destroy ghostbsd >/dev/null 2>/dev/null || true
  umount ${release} >/dev/null 2>/dev/null || true

  # Remove old build directory if it exists
  if [ -d "${cd_root}" ] ; then
    chflags -R noschg ${cd_root}
    rm -rf ${cd_root}
  fi

  # Detach memory device if previously attached
  mdconfig -d -u 0 >/dev/null 2>/dev/null || true
  
  # Remove old pool image if it exists
  if [ -f "${livecd}/pool.img" ] ; then
    rm ${livecd}/pool.img
  fi

  # Create necessary directories for the build
  mkdir -p ${livecd} ${base} ${iso} ${packages_storage}  ${release}

  # Create a new pool image file - Updated for 8GB minimum
  POOL_SIZE='6656M'  # 6.5GB in MB (6.5 * 1024 = 6656) - increased from 6g to accommodate larger 8GB systems
  log "Creating ${POOL_SIZE} pool image for 8GB minimum system..."
  truncate -s ${POOL_SIZE} ${livecd}/pool.img
  
  # Attach the pool image as a memory disk
  mdconfig -f ${livecd}/pool.img -u 0

  # Attempt to create the ZFS pool with error handling
  log "Creating ZFS pool 'ghostbsd' with 8GB optimizations..."
  if ! zpool create -O mountpoint="${release}" -O compression=zstd-9 ghostbsd /dev/md0; then
    # Provide detailed error message in case of failure
    log "Error: Failed to create ZFS pool 'ghostbsd' with the following command:"
    log "zpool create -O mountpoint='${release}' -O compression=zstd-9 ghostbsd /dev/md0"
    
    # Clean up resources in case of failure
    zpool destroy ghostbsd 2>/dev/null || true
    mdconfig -d -u 0 2>/dev/null || true
    rm -f ${livecd}/pool.img 2>/dev/null || true
    
    # Exit with an error code
    exit 1
  fi
  
  # Verify pool creation
  log "Verifying ZFS pool..."
  zpool status ghostbsd
  zpool list ghostbsd
  
  log "Workspace setup completed successfully for 8GB minimum system"
}

# Enhanced base function with login.conf fix for cap_mkdb
base()
{
  log "=== Setting up base system with login.conf fix ==="
  if [ "${desktop}" = "test" ] ; then
    base_list="$(cat "${cwd}/packages/test_base")"
    vital_base="$(cat "${cwd}/packages/vital/test_base")"
  else
    base_list="$(cat "${cwd}/packages/base")"
    vital_base="$(cat "${cwd}/packages/vital/base")"
  fi
  
  mkdir -p ${release}/etc
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  
  # CRITICAL FIX: Create a proper login.conf BEFORE installing packages
  log "Creating login.conf to prevent cap_mkdb errors..."
  cat > "${release}/etc/login.conf" << 'EOF'
# login.conf - login class capabilities database.
#
# Remember to rebuild the database after each change to this file:
#
#	cap_mkdb /etc/login.conf
#
# This file controls resource limits, accounting limits and
# default user environment settings.
#

# Default settings effectively disable resource limits
default:\
	:passwd_format=sha512:\
	:copyright=/etc/COPYRIGHT:\
	:welcome=/etc/motd:\
	:setenv=MAIL=/var/mail/$,BLOCKSIZE=K:\
	:path=/sbin /bin /usr/sbin /usr/bin /usr/games /usr/local/sbin /usr/local/bin ~/bin:\
	:nologin=/var/run/nologin:\
	:cputime=unlimited:\
	:datasize=unlimited:\
	:stacksize=unlimited:\
	:memorylocked=64K:\
	:memoryuse=unlimited:\
	:filesize=unlimited:\
	:coredumpsize=unlimited:\
	:openfiles=unlimited:\
	:maxproc=unlimited:\
	:sbsize=unlimited:\
	:vmemoryuse=unlimited:\
	:swapuse=unlimited:\
	:pseudoterminals=unlimited:\
	:priority=0:\
	:ignoretime@:\
	:umask=022:

# A collection of common class names - forward them all to 'default'
standard:\
	:tc=default:
xuser:\
	:tc=default:
staff:\
	:tc=default:
daemon:\
	:memorylocked=128M:\
	:tc=default:
news:\
	:tc=default:
dialer:\
	:tc=default:

# Root can always login
root:\
	:ignorenologin:\
	:memorylocked=unlimited:\
	:tc=default:
EOF

  # Create the database file to prevent cap_mkdb errors
  log "Creating login.conf.db to prevent package installation errors..."
  # Don't try to run cap_mkdb in chroot before base packages are installed
  # Just create a minimal database file to prevent package installation failures
  touch "${release}/etc/login.conf.db"
  
  # Verify the files were created
  if [ ! -f "${release}/etc/login.conf" ]; then
    error_exit "Failed to create login.conf"
  fi
  log "login.conf created successfully"
  
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${packages_storage} ${release}/var/cache/pkg
  
  # Install base packages with enhanced error handling
  log "Installing base packages with login.conf fix..."
  # shellcheck disable=SC2086
  if ! pkg -r ${release} -R "${cwd}/pkg/" install -y -r ${PKG_CONF}_base ${base_list}; then
    log "ERROR: Base package installation failed"
    log "Checking login.conf status:"
    ls -la ${release}/etc/login.conf*
    log "Recent package installation logs:"
    tail -20 /var/log/messages 2>/dev/null || echo "No system logs available"
    error_exit "Base package installation failed"
  fi
  
  # shellcheck disable=SC2086
  pkg -r ${release} -R "${cwd}/pkg/" set -y -v 1 ${vital_base}
  
  # Clean up
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  touch ${release}/etc/fstab
  mkdir ${release}/cdrom ${release}/mnt ${release}/media
  
  log "Base system setup completed"
}

set_ghostbsd_version()
{
  if [ "${build_type}" = "testing" ] || [ "${build_type}" = "unstable" ] ; then
    # Add date suffix for testing and unstable builds
    base_version="-$(cat ${release}/etc/version)"
    date_suffix="-$(date +%m-%d-%H)"
    version="${base_version}${date_suffix}"
    log "Adding date suffix for ${build_type} build: ${date_suffix}"
  else
    version="-$(cat ${release}/etc/version)"
  fi
  iso_path="${iso}/${label}${version}${release_stamp}${time_stamp}${community}.iso"
  log "ISO will be created as: $(basename "$iso_path")"
}

# Enhanced packages_software with additional login.conf protection
packages_software()
{
  log "=== Installing desktop and software packages with enhanced protection ==="
  
  if [ "${build_type}" = "unstable" ] ; then
    cp pkg/GhostBSD_Unstable.conf ${release}/etc/pkg/GhostBSD.conf
  fi
  if [ "${build_type}" = "testing" ] ; then
    cp pkg/GhostBSD_Testing.conf ${release}/etc/pkg/GhostBSD.conf
  fi
  
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${packages_storage} ${release}/var/cache/pkg
  mount -t devfs devfs ${release}/dev
  
  # Double-check login.conf before package installation
  log "Verifying login.conf before package installation..."
  if [ ! -f "${release}/etc/login.conf" ]; then
    log "WARNING: login.conf missing, recreating..."
    # Re-run the login.conf creation from base() function
    cat > "${release}/etc/login.conf" << 'EOF'
# Minimal login.conf for package installation
default:\
	:passwd_format=sha512:\
	:path=/sbin /bin /usr/sbin /usr/bin /usr/games /usr/local/sbin /usr/local/bin ~/bin:\
	:umask=022:
EOF
    chroot ${release} cap_mkdb /etc/login.conf 2>/dev/null || touch "${release}/etc/login.conf.db"
  fi
  
  # Verify login.conf.db exists
  if [ ! -f "${release}/etc/login.conf.db" ]; then
    log "Creating login.conf.db..."
    chroot ${release} cap_mkdb /etc/login.conf 2>/dev/null || touch "${release}/etc/login.conf.db"
  fi
  
  de_packages="$(cat "${cwd}/packages/${desktop}")"
  common_packages="$(cat "${cwd}/packages/common")"
  drivers_packages="$(cat "${cwd}/packages/drivers")"
  vital_de_packages="$(cat "${cwd}/packages/vital/${desktop}")"
  vital_common_packages="$(cat "${cwd}/packages/vital/common")"
  
  # Install packages with better error handling
  log "Installing desktop environment and common packages..."
  # shellcheck disable=SC2086
  if ! pkg -c ${release} install -y ${de_packages} ${common_packages} ${drivers_packages}; then
    log "ERROR: Package installation failed"
    log "Checking for cap_mkdb related errors:"
    dmesg | tail -10
    log "Login.conf status:"
    ls -la ${release}/etc/login.conf*
    
    # Try to fix and retry once
    log "Attempting to fix login.conf and retry..."
    chroot ${release} cap_mkdb /etc/login.conf 2>/dev/null || true
    
    # shellcheck disable=SC2086
    if ! pkg -c ${release} install -y ${de_packages} ${common_packages} ${drivers_packages}; then
      error_exit "Package installation failed even after login.conf fix"
    fi
  fi
  
  # shellcheck disable=SC2086
  pkg -c ${release} set -y -v 1 ${vital_de_packages} ${vital_common_packages}
  
  mkdir -p ${release}/proc
  mkdir -p ${release}/compat/linux/proc
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  
  log "Package installation completed successfully"
}

fetch_x_drivers_packages()
{
  log "=== Fetching X driver packages ==="
  if [ "${build_type}" = "release" ] ; then
    pkg_url=$(pkg -R pkg/ -vv | grep '/stable.*/latest' | cut -d '"' -f2)
  elif [ "${build_type}" = "testing" ]; then
    pkg_url=$(pkg -R pkg/ -vv | grep '/testing.*/latest' | cut -d '"' -f2)
  else
    pkg_url=$(pkg -R pkg/ -vv | grep '/unstable.*/latest' | cut -d '"' -f2)
  fi
  mkdir ${release}/xdrivers
  yes | pkg -R "${cwd}/pkg/" update
  # TODO: Do not forgot to fix that when we move to xlibre.
  #  We only skipping xlibre for now until we are doe testing.
  echo """$(pkg -R "${cwd}/pkg/" rquery -x -r ${PKG_CONF} '%n %n-%v.pkg' 'nvidia-driver' | grep -v libva | grep -v xlibre)""" > ${release}/xdrivers/drivers-list
  pkg_list="""$(pkg -R "${cwd}/pkg/" rquery -x -r ${PKG_CONF} '%n-%v.pkg' 'nvidia-driver' | grep -v libva| grep -v xlibre)"""
  for line in $pkg_list ; do
    fetch -o ${release}/xdrivers "${pkg_url}/All/$line"
  done
  ls ${release}/xdrivers
  
  log "X driver packages fetched"
}

rc()
{
  log "=== Configuring system services ==="
  chroot ${release} touch /etc/rc.conf
  chroot ${release} sysrc hostname='livecd'
  chroot ${release} sysrc zfs_enable="YES"
  chroot ${release} sysrc kld_list="linux linux64 cuse fusefs hgame"
  chroot ${release} sysrc linux_enable="YES"
  chroot ${release} sysrc devfs_enable="YES"
  chroot ${release} sysrc devfs_system_ruleset="devfsrules_common"
  chroot ${release} sysrc moused_enable="YES"
  chroot ${release} sysrc dbus_enable="YES"
  chroot ${release} sysrc lightdm_enable="NO"
  chroot ${release} sysrc webcamd_enable="YES"
  chroot ${release} sysrc firewall_enable="YES"
  chroot ${release} sysrc firewall_type="workstation"
  chroot ${release} sysrc cupsd_enable="YES"
  chroot ${release} sysrc avahi_daemon_enable="YES"
  chroot ${release} sysrc avahi_dnsconfd_enable="YES"
  chroot ${release} sysrc ntpd_enable="YES"
  chroot ${release} sysrc ntpd_sync_on_start="YES"
  chroot ${release} sysrc clear_tmp_enable="YES"
  
  log "System services configured"
}

ghostbsd_config()
{
  log "=== Applying GhostBSD-specific configuration ==="
  # echo "gop set 0" >> ${release}/boot/loader.rc.local
  mkdir -p ${release}/usr/local/share/ghostbsd
  echo "${desktop}" > ${release}/usr/local/share/ghostbsd/desktop
  # Mkdir for linux compat to ensure /etc/fstab can mount when booting LiveCD
  chroot ${release} mkdir -p /compat/linux/dev/shm
  chroot ${release} mkdir -p /compat/linux/proc
  chroot ${release} mkdir -p /compat/linux/sys
  # Add /boot/entropy file
  chroot ${release} touch /boot/entropy
  # default GhostBSD to local time instead of UTC
  chroot ${release} touch /etc/wall_cmos_clock
  
  log "GhostBSD configuration applied"
}

# Clean desktop_config function that avoids user creation conflicts
desktop_config()
{
  log "=== Configuring desktop environment: ${desktop} ==="
  
  # Source common configuration functions (but only call the safe ones)
  log "Loading common configuration functions..."
  . "${cwd}/common_config/base-setting.sh"
  . "${cwd}/common_config/gitpkg.sh" 
  . "${cwd}/common_config/finalize.sh"
  
  # Apply base patches and settings
  log "Applying base system patches..."
  patch_etc_files
  
  # Install git packages
  log "Installing git-based packages..."
  git_pc_sysinstall
  git_gbi
  git_install_station
  git_setup_station
  
  # Run desktop-specific configuration script (this handles user setup)
  log "Running desktop-specific configuration script..."
  sh "${cwd}/desktop_config/${desktop}.sh"
  
  # Apply final setup
  log "Applying final system setup..."
  final_setup
  
  log "Desktop configuration completed"
}

# Enhanced uzip function with zstd compression
uzip()
{
  log "=== Creating zstd compressed system image ==="
  
  install -o root -g wheel -m 755 -d "${cd_root}"
  mkdir "${cd_root}/data"
  
  # Pre-send analysis
  log "Analyzing system before image creation..."
  
  # Check available space for system.img
  cd_data_avail=$(df "${cd_root}/data" | tail -1 | awk '{print $4}')
  cd_data_avail_gb=$((cd_data_avail / 1024 / 1024))
  log "Available space for system.img: ${cd_data_avail_gb}GB"
  
  if [ $cd_data_avail_gb -lt 8 ]; then
    error_exit "Insufficient space for system.img. Need at least 8GB, have ${cd_data_avail_gb}GB"
  fi
  
  # Analyze ZFS pool status
  log "ZFS pool analysis:"
  zpool list ghostbsd
  zfs list ghostbsd
  
  # Check for any pool issues
  if ! zpool status ghostbsd | grep -q "state: ONLINE"; then
    error_exit "ZFS pool 'ghostbsd' is not in ONLINE state"
  fi
  
  # Force synchronization before snapshot
  log "Synchronizing pool before snapshot..."
  sync
  zpool sync ghostbsd
  sleep 3
  
  # Create snapshot with verification
  log "Creating clean snapshot..."
  if ! zfs snapshot ghostbsd@clean; then
    error_exit "Failed to create snapshot ghostbsd@clean"
  fi
  
  # Verify snapshot exists
  if ! zfs list -t snapshot ghostbsd@clean >/dev/null 2>&1; then
    error_exit "Snapshot ghostbsd@clean was not created properly"
  fi
  
  # Estimate send size if possible
  log "Estimating send size..."
  if command -v zstreamdump >/dev/null 2>&1; then
    estimated_size=$(zfs send -nP ghostbsd@clean 2>/dev/null | tail -1 | awk '{print $2}' 2>/dev/null || echo "unknown")
    if [ "$estimated_size" != "unknown" ]; then
      estimated_mb=$((estimated_size / 1024 / 1024))
      log "Estimated uncompressed send size: ${estimated_mb}MB"
    fi
  fi
  
  # Start background monitoring - zstd only
  log "Starting background monitoring..."
  (
    while true; do
      sleep 30
      # Check for zstd or uncompressed files
      current_size=0
      current_file=""
      if [ -f "${cd_root}/data/system.img.zst" ]; then
        current_size=$(stat -f %z "${cd_root}/data/system.img.zst" 2>/dev/null || echo 0)
        current_file="system.img.zst"
      elif [ -f "${cd_root}/data/system.img" ]; then
        current_size=$(stat -f %z "${cd_root}/data/system.img" 2>/dev/null || echo 0)
        current_file="system.img"
      fi
      
      if [ "$current_size" -gt 0 ]; then
        current_mb=$((current_size / 1024 / 1024))
        log "${current_file} current size: ${current_mb}MB"
      fi
      
      # Check if zfs send or zstd process is still running
      if ! pgrep -f "zfs send\|zstd" >/dev/null 2>&1; then
        break
      fi
    done
  ) &
  MONITOR_PID=$!
  
  # Enhanced ZFS send with zstd compression
  log "Creating zstd compressed system image..."
  send_success=false
  compression_used="none"
  
  # Use zstd compression (confirmed working)
  if command -v zstd >/dev/null 2>&1; then
    log "Using zstd -9 compression..."
    if zfs send -v -p ghostbsd@clean | zstd -9 -T0 > "${cd_root}/data/system.img.zst" 2>"${cd_root}/data/zfs_send.log"; then
      log "Zstd compressed send completed successfully"
      send_success=true
      compression_used="zstd"
    else
      log "Zstd compressed send failed:"
      cat "${cd_root}/data/zfs_send.log"
    fi
  else
    log "ERROR: zstd not available for compression"
  fi
  
  # Fallback: uncompressed only
  if [ "$send_success" != "true" ]; then
    log "Zstd failed, trying uncompressed fallback..."
    if zfs send -v -p ghostbsd@clean > "${cd_root}/data/system.img" 2>"${cd_root}/data/zfs_send_fallback.log"; then
      log "Uncompressed fallback send completed successfully"
      send_success=true
      compression_used="none"
    else
      log "All send methods failed:"
      cat "${cd_root}/data/zfs_send_fallback.log"
      send_success=false
    fi
  fi
  
  # Stop monitoring
  kill $MONITOR_PID 2>/dev/null || true
  
  # Verify the created image and report compression results
  if [ "$send_success" = "true" ] && [ "$compression_used" = "zstd" ] && [ -f "${cd_root}/data/system.img.zst" ]; then
    # Zstd compressed image exists
    img_size=$(stat -f %z "${cd_root}/data/system.img.zst")
    img_size_mb=$((img_size / 1024 / 1024))
    log "Final system.img.zst size: ${img_size_mb}MB (zstd compressed)"
    
    # Create compression metadata file
    echo "zstd" > "${cd_root}/data/compression.txt"
    
    # Calculate compression ratio if we have the estimated size
    if [ "$estimated_size" != "unknown" ] && [ -n "$estimated_mb" ]; then
      compression_ratio=$((100 - (img_size_mb * 100 / estimated_mb)))
      log "Compression ratio: ${compression_ratio}% reduction (${estimated_mb}MB -> ${img_size_mb}MB)"
    fi
    
    # Comprehensive validation
    if [ $img_size_mb -lt 100 ]; then
      error_exit "system.img.zst appears truncated (${img_size_mb}MB is too small)"
    fi
    
    log "Zstd compressed system image creation completed successfully: ${img_size_mb}MB"
    
  elif [ "$send_success" = "true" ] && [ "$compression_used" = "none" ] && [ -f "${cd_root}/data/system.img" ]; then
    # Uncompressed image exists
    img_size=$(stat -f %z "${cd_root}/data/system.img")
    img_size_mb=$((img_size / 1024 / 1024))
    log "Final system.img size: ${img_size_mb}MB (uncompressed)"
    
    # Create compression metadata file
    echo "none" > "${cd_root}/data/compression.txt"
    
    # Comprehensive validation
    if [ $img_size_mb -lt 100 ]; then
      error_exit "system.img appears truncated (${img_size_mb}MB is too small)"
    fi
    
    log "Uncompressed system image creation completed successfully: ${img_size_mb}MB"
  else
    error_exit "System image creation failed"
  fi
}

ramdisk()
{
  log "=== Creating ramdisk ==="
  ramdisk_root="${cd_root}/data/ramdisk"
  mkdir -p "${ramdisk_root}"
  cd "${release}"
  tar -cf - rescue | tar -xf - -C "${ramdisk_root}"
  cd "${cwd}"
  install -o root -g wheel -m 755 "init.sh.in" "${ramdisk_root}/init.sh"
  sed "s/@VOLUME@/GHOSTBSD/" "init.sh.in" > "${ramdisk_root}/init.sh"
  mkdir "${ramdisk_root}/dev"
  mkdir "${ramdisk_root}/etc"
  touch "${ramdisk_root}/etc/fstab"
  install -o root -g wheel -m 755 "rc.in" "${ramdisk_root}/etc/rc"
  cp ${release}/etc/login.conf ${ramdisk_root}/etc/login.conf
  makefs -b '10%' "${cd_root}/data/ramdisk.ufs" "${ramdisk_root}"
  gzip "${cd_root}/data/ramdisk.ufs"
  rm -rf "${ramdisk_root}"
  
  log "Ramdisk creation completed"
}

boot()
{
  log "=== Preparing boot environment ==="
  cd "${release}"
  tar -cf - boot | tar -xf - -C "${cd_root}"
  cp COPYRIGHT ${cd_root}/COPYRIGHT
  cd "${cwd}"
  cp LICENSE ${cd_root}/LICENSE
  cp -R boot/ ${cd_root}/boot/
  mkdir ${cd_root}/etc

  # Try to unmount dev and release if mounted
  umount ${release}/dev >/dev/null 2>/dev/null || true
  umount ${release} >/dev/null 2>/dev/null || true
  
  # Export ZFS pool and ensure it's clean
  log "Exporting ZFS pool..."
  zpool export ghostbsd
  timeout=10
  while zpool status ghostbsd >/dev/null 2>&1; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
      log "Warning: ZFS pool export timeout, but continuing..."
      break
    fi
  done
  
  log "Boot environment preparation completed"
}

image()
{
  log "=== Creating ISO image ==="
  cd script
  sh mkisoimages.sh -b $label "$iso_path" ${cd_root}
  cd -
  
  # Verify ISO was created
  if [ ! -f "$iso_path" ]; then
    error_exit "ISO image was not created"
  fi
  
  iso_size=$(stat -f %z "$iso_path")
  iso_size_mb=$((iso_size / 1024 / 1024))
  log "Created ISO: $(basename "$iso_path") (${iso_size_mb}MB)"
  
  ls -lh "$iso_path"
  cd ${iso}
  shafile=$(echo "${iso_path}" | cut -d / -f6).sha256
  torrent=$(echo "${iso_path}" | cut -d / -f6).torrent
  tracker1="http://tracker.openbittorrent.com:80/announce"
  tracker2="udp://tracker.opentrackr.org:1337"
  tracker3="udp://tracker.coppersurfer.tk:6969"
  log "Creating sha256 checksum..."
  sha256 "$(echo "${iso_path}" | cut -d / -f6)" > "${iso}/${shafile}"
  log "Creating torrent file..."
  transmission-create -o "${iso}/${torrent}" -t ${tracker1} -t ${tracker2} -t ${tracker3} "${iso_path}"
  chmod 644 "${iso}/${torrent}"
  cd -
  
  log "=== Build completed successfully ==="
  log "ISO: $iso_path (${iso_size_mb}MB)"
  log "SHA256: ${iso}/${shafile}"
  log "Torrent: ${iso}/${torrent}"
}

# Execute build pipeline with enhanced integration
log "=== Starting GhostBSD build process ==="
log "Desktop: ${desktop}, Build type: ${build_type}, ZFS control: ${zfs_control}"

workspace
base
set_ghostbsd_version
packages_software
fetch_x_drivers_packages
rc
desktop_config
ghostbsd_config
uzip
ramdisk
boot
image

log "=== GhostBSD build process completed successfully ==="
