ghostbsd-build
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is to quickly generate live images for GhostBSD.

## Features
* Build GhostBSD from packages
* Mate and XFCE desktop environments
* Hybrid DVD/USB image

## Graphics support
* Compatible with VirtualBox, VMware, NVIDIA graphics out of box
* SCFB support with automatic best resolution for UEFI enabled systems with Intel/AMD graphics

## System requirements
* Latest version of GhostBSD 
* 20GB of free disk space
* 8GB of free memory

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
./build.sh -d mate -b unstable
```
or
```
./build.sh -d mate -b release
```

#### (Option) To build GhostBSD with __XFCE__ as default desktop
```
./build.sh -d xfce -b unstable
```   

#### (Option) To build GhostBSD with __Gershwin__ as default desktop
```
./build.sh -d gershwin -b unstable
```   

## Burn an image to cd:
```
cdrecord /usr/local/ghostbsd-build/iso/GhostBSD-22.01.12.iso
```

## Write an image to usb stick:
```
dd if=/usr/local/ghostbsd-build/iso/GhostBSD-22.01.12.iso of=/dev/da0 bs=4m
```
