ghostbsd-build
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is quickly generate live images for GhostBSD.

## Features
* Build GhostBSD with GhostBSD
* Mate, XFCE, and KDE desktop environments
* Hybrid DVD/USB image

## Graphics Support
* Compatible with VirtualBox, VMware, NVIDIA graphics out of box
* SCFB support with automatic best resolution for UEFI enabled systems with Intel/AMD graphics

## System Requirements
* Latest version of GhostBSD 
* 20GB of free disk space
* 4GB of free memory

Note: GhostBSD 19.09 and later should be used to build ISO.

## Initial Setup
Install the required packages:
```
pkg install git transmission-cli rsync
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
Enter the directory for running the LiveCD build script:
```
cd ghostbsd-build
```
To build a GhostBSD with __MATE__ as default desktop
```
./build.sh mate
```   
(Option) To build GhostBSD with __XFCE__ as default desktop
```
./build.sh xfce
```   
(Option) To build GhostBSD with __Cinnamon__ as default desktop
```
./build.sh cinnamon
```   
(Option) To build GhostBSD the default __MATE__ desktop
```
./build.sh
```    

## Burn an image to cd:
```
cdrecord /usr/local/ghostbsd-build/iso/GhostBSD19.10.iso
```

## Write an image to usb stick:
```
dd if=/usr/local/ghostbsd-build/iso/GhostBSD19.10.iso of=/dev/da0 bs=4m
```
