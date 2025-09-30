
ghostbsd-build  (Greenfield)
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is to quickly generate live images for GhostBSD.

## Features
* Build GhostBSD from packages
* Multiple desktop environments (Mate, XFCE, Gershwin, Plasma, and more)
* Hybrid DVD/USB image
* Configurable ZFS memory management for build optimization
* Gzip compression support for smaller system images
* Enhanced error handling and debugging

## Graphics support
* Compatible with VirtualBox, VMware, NVIDIA graphics out of the box
* SCFB support with automatic best resolution for UEFI enabled systems with Intel/AMD graphics

## System requirements
* Latest version of GhostBSD 
* 20GB of free disk space
* **8GB of free memory minimum** (16GB+ recommended for optimal performance)

Note: GhostBSD 25.02-R14.3p2 and later should be used to build ISO.

## Initial setup
Install the required packages:
```
pkg install git transmission-utils rsync
```
Make sure to have linux64 kernel module loaded
```
kldload linux64
sysrc -f /etc/rc.conf kld_list="linux64"
```
Clone the repo:
```
git clone https://www.github.com/ghostbsd/ghostbsd-build.git
```

## Starting a build

#### Enter the directory for running the LiveCD build script:
```
cd ghostbsd-build
```

#### To build a GhostBSD with __MATE__ as default desktop
```
./build.sh -d mate -b release
```
or for unstable builds:
```
./build.sh -d mate -b unstable
```

#### To build GhostBSD with __XFCE__ as default desktop
```
./build.sh -d xfce -b release
```   
#### (Option) To build GhostBSD with __KDE Plasma 6__ as default desktop
```
./build.sh -d plasma -b unstable
```   

#### To build GhostBSD with __Gershwin__ as default desktop
```
./build.sh -d gershwin -b release
```   

## Build options

#### ZFS Memory Control
The build system includes configurable ZFS ARC memory management to optimize build performance without permanently affecting your host system:

```bash
# Safe mode - never modify host ZFS settings (safest)
./build.sh -d mate -b release -z off

# Default mode - smart tuning only when beneficial
./build.sh -d mate -b release

# Conservative mode - only tune if ARC uses >60% of RAM
./build.sh -d mate -b release -z conservative

# Aggressive mode - always optimize for build performance
./build.sh -d mate -b release -z aggressive
```

**ZFS Control Options:**
- `off` - Never modify host ZFS ARC settings (safest)
- `auto` - Only tune if current ARC significantly exceeds build needs (default)
- `conservative` - Only tune if ARC is using >60% of system RAM
- `aggressive` - Always apply build-optimized settings
- `restore` - Same as aggressive but explicitly shows restore intent

All modes except 'off' automatically restore original ZFS settings after build completion.

#### Getting help
```
./build.sh -h
```

## Burn an image to cd:
```
cdrecord /usr/local/ghostbsd-build/iso/GhostBSD-25.02-R14.3p2.iso
```

## Write an image to usb stick:
```
dd if=/usr/local/ghostbsd-build/iso/GhostBSD-25.02-R14.3p2.iso of=/dev/da0 bs=4m
```

## Troubleshooting

#### Build fails with memory errors
Ensure you have at least 8GB of RAM. For systems with exactly 8GB, consider:
```bash
# Use conservative ZFS tuning to leave more memory available
./build.sh -d mate -b release -z conservative
```

#### Build hangs during image creation
This usually indicates insufficient memory or disk space. Check requirements and consider closing other applications during the build.

#### ZFS ARC concerns
If you're concerned about the build process affecting your host system's ZFS performance:
```bash
# Use safe mode to never modify host ZFS settings
./build.sh -d mate -b release -z off
```

