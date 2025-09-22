#!/usr/bin/env sh

set -e -u

cwd="$(realpath)"
export cwd

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
  printf "Usage: %s -d desktop -b build_type\n" "$0"
  printf "\t-h for help\n"
  printf "\t-d Desktop: %s\n" "${desktop_list}"
  printf "\t-b Build type: unstable, testing, or release\n"
  printf "\t-t Test: FreeBSD os packages\n"
   exit 1 # Exit script after printing help
}

# Set mate and release to be default
export desktop="mate"
export build_type="release"

while getopts "d:b:th" opt
do
   case "$opt" in
      'd') export desktop="$OPTARG" ;;
      'b') export build_type="$OPTARG" ;;
      't') export desktop="test" ; build_type="test";;
      'h') help_function ;;
      '?') help_function ;;
      *) help_function ;;
   esac
done

if [ "${build_type}" = "testing" ] ; then
  PKG_CONF="GhostBSD_Testing"
elif [ "${build_type}" = "release" ] ; then
  PKG_CONF="GhostBSD"
elif [ "${build_type}" = "unstable" ] ; then
  PKG_CONF="GhostBSD_Unstable"
else
  printf "\t-b Build type: unstable, testing, or release"
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

# Enhanced workspace function with integrated diagnostics
workspace()
{
  log "=== Enhanced Workspace Setup with Diagnostics ==="
  
  # Pre-build environment analysis
  log "Analyzing build environment..."
  
  # 1. Memory Analysis
  realmem=$(sysctl -n hw.realmem)
  realmem_gb=$((realmem / 1024 / 1024 / 1024))
  log "Available memory: ${realmem_gb}GB"
  
  if [ $realmem_gb -lt 8 ]; then
    log "WARNING: Less than 8GB RAM detected. Build may fail due to memory pressure."
    log "Consider using a system with more RAM or enabling swap."
  fi
  
  # 2. Disk Space Analysis
  log "Analyzing disk space..."
  workdir_avail=$(df /usr/local | tail -1 | awk '{print $4}')
  workdir_avail_gb=$((workdir_avail / 1024 / 1024))
  log "Available space in /usr/local: ${workdir_avail_gb}GB"
  
  if [ $workdir_avail_gb -lt 15 ]; then
    error_exit "Insufficient disk space. Need at least 15GB free in /usr/local, have ${workdir_avail_gb}GB"
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
  
  # 4. ZFS Memory Tuning
  if kldstat | grep -q zfs; then
    log "ZFS detected, applying memory tuning..."
    # Limit ARC to 25% of system memory during build to prevent pressure
    arc_max=$((realmem / 4))
    sysctl vfs.zfs.arc_max=$arc_max >/dev/null 2>&1 || true
    log "Set ZFS ARC max to $((arc_max / 1024 / 1024))MB"
  fi
  
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

  # Create a new pool image file of 6GB
  POOL_SIZE='6g'
  log "Creating ${POOL_SIZE} pool image..."
  truncate -s ${POOL_SIZE} ${livecd}/pool.img
  
  # Attach the pool image as a memory disk
  mdconfig -f ${livecd}/pool.img -u 0

  # Attempt to create the ZFS pool with error handling
  log "Creating ZFS pool 'ghostbsd'..."
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
  
  log "Workspace setup completed successfully"
}

base()
{
  log "=== Setting up base system ==="
  if [ "${desktop}" = "test" ] ; then
    base_list="$(cat "${cwd}/packages/test_base")"
    vital_base="$(cat "${cwd}/packages/vital/test_base")"
  else
    base_list="$(cat "${cwd}/packages/base")"
    vital_base="$(cat "${cwd}/packages/vital/base")"
  fi
  mkdir -p ${release}/etc
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  mkdir -p ${release}/var/cache/pkg
  mount_nullfs ${packages_storage} ${release}/var/cache/pkg
  # shellcheck disable=SC2086
  pkg -r ${release} -R "${cwd}/pkg/" install -y -r ${PKG_CONF}_base ${base_list}
  # shellcheck disable=SC2086
  pkg -r ${release} -R "${cwd}/pkg/" set -y -v 1 ${vital_base}
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  touch ${release}/etc/fstab
  mkdir ${release}/cdrom ${release}/mnt ${release}/media
  
  log "Base system setup completed"
}

set_ghostbsd_version()
{
  if [ "${desktop}" = "test" ] ; then
    version="$(date +%Y-%m-%d)"
  else
    version="-$(cat ${release}/etc/version)"
  fi
  iso_path="${iso}/${label}${version}${release_stamp}${time_stamp}${community}.iso"
  log "ISO will be created as: $(basename $iso_path)"
}

packages_software()
{
  log "=== Installing desktop and software packages ==="
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
  de_packages="$(cat "${cwd}/packages/${desktop}")"
  common_packages="$(cat "${cwd}/packages/common")"
  drivers_packages="$(cat "${cwd}/packages/drivers")"
  vital_de_packages="$(cat "${cwd}/packages/vital/${desktop}")"
  vital_common_packages="$(cat "${cwd}/packages/vital/common")"
  # shellcheck disable=SC2086
  pkg -c ${release} install -y ${de_packages} ${common_packages} ${drivers_packages}
  # shellcheck disable=SC2086
  pkg -c ${release} set -y -v 1 ${vital_de_packages}  ${vital_common_packages}
  mkdir -p ${release}/proc
  mkdir -p ${release}/compat/linux/proc
  rm ${release}/etc/resolv.conf
  umount ${release}/var/cache/pkg
  
  log "Package installation completed"
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

desktop_config()
{
  log "=== Configuring desktop environment: ${desktop} ==="
  # run config for GhostBSD flavor
  sh "${cwd}/desktop_config/${desktop}.sh"
  log "Desktop configuration completed"
}

# Enhanced uzip function with comprehensive monitoring and fallbacks
uzip()
{
  log "=== Creating system image with enhanced monitoring ==="
  
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
      log "Estimated send size: ${estimated_mb}MB"
    fi
  fi
  
  # Start background monitoring
  log "Starting background monitoring..."
  (
    while true; do
      sleep 30
      if [ -f "${cd_root}/data/system.img" ]; then
        current_size=$(stat -f %z "${cd_root}/data/system.img" 2>/dev/null || echo 0)
        current_mb=$((current_size / 1024 / 1024))
        log "system.img current size: ${current_mb}MB"
      fi
      
      # Check if zfs send process is still running
      if ! pgrep -f "zfs send" >/dev/null 2>&1; then
        break
      fi
    done
  ) &
  MONITOR_PID=$!
  
  # Method 1: Enhanced simple send
  log "Attempting enhanced ZFS send..."
  send_success=false
  
  if zfs send -v -p ghostbsd@clean > "${cd_root}/data/system.img" 2>"${cd_root}/data/zfs_send.log"; then
    log "Enhanced send completed successfully"
    send_success=true
  else
    log "Enhanced send failed, trying fallback methods..."
    cat "${cd_root}/data/zfs_send.log"
    
    # Method 2: Send without compression
    log "Trying send with compression disabled..."
    original_compression=$(zfs get -H -o value compression ghostbsd)
    zfs set compression=off ghostbsd
    
    if zfs send -v -p ghostbsd@clean > "${cd_root}/data/system.img" 2>"${cd_root}/data/zfs_send2.log"; then
      log "Send without compression completed successfully"
      send_success=true
    else
      log "Send without compression failed, trying raw send..."
      cat "${cd_root}/data/zfs_send2.log"
      
      # Method 3: Basic raw send
      if zfs send ghostbsd@clean > "${cd_root}/data/system.img" 2>"${cd_root}/data/zfs_send3.log"; then
        log "Raw send completed successfully"
        send_success=true
      else
        log "All ZFS send methods failed:"
        cat "${cd_root}/data/zfs_send3.log"
        send_success=false
      fi
    fi
    
    # Restore original compression
    zfs set compression="$original_compression" ghostbsd
  fi
  
  # Stop monitoring
  kill $MONITOR_PID 2>/dev/null || true
  
  # Verify the created image
  if [ "$send_success" = "true" ] && [ -f "${cd_root}/data/system.img" ]; then
    img_size=$(stat -f %z "${cd_root}/data/system.img")
    img_size_mb=$((img_size / 1024 / 1024))
    log "Final system.img size: ${img_size_mb}MB"
    
    # Comprehensive validation
    if [ $img_size_mb -lt 100 ]; then
      error_exit "system.img appears truncated (${img_size_mb}MB is too small)"
    fi
    
    # Test if it's a valid ZFS stream
    log "Validating ZFS stream format..."
    if command -v zstreamdump >/dev/null 2>&1; then
      if ! zstreamdump "${cd_root}/data/system.img" >/dev/null 2>&1; then
        error_exit "system.img is not a valid ZFS stream"
      fi
      log "ZFS stream validation passed"
    else
      log "zstreamdump not available, skipping stream validation"
    fi
    
    log "System image creation completed successfully: ${img_size_mb}MB"
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

# Execute build pipeline
log "=== Starting GhostBSD build process ==="
log "Desktop: ${desktop}, Build type: ${build_type}"

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
