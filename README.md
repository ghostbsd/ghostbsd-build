ghostbsd-build
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is quickly generate live images for GhostBSD.

## Features
* Build GhostBSD from packages
* Mate, XFCE, Cinnamon and KDE desktop environments
* Hybrid DVD/USB image

## Graphics support
* Compatible with VirtualBox, VMware, NVIDIA graphics out of box
* SCFB support with automatic best resolution for UEFI enabled systems with Intel/AMD graphics

## System requirements
* Latest version of GhostBSD 
* 20GB of free disk space
* 8GB of free memory

Note: GhostBSD 20.04 and later should be used to build ISO.

## Initial setup
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
## Starting a build
#### Enter the directory for running the LiveCD build script:
```
cd ghostbsd-build
```

#### To build a GhostBSD with __MATE__ as default desktop
```
./build.sh
```
or
```
./build.sh -d mate
```

#### (Option) To build GhostBSD with __XFCE__ as default desktop
```
./build.sh -d xfce
```   

#### (Option) To build GhostBSD with __Cinnamon__ as default desktop
```
./build.sh -d cinnamon
```   

#### (Option) To build GhostBSD the default __KDE__ desktop
```
./build.sh -d kde
```    

#### (Option) To build GhostBSD release __MATE__ desktop
```
./build.sh -r release
```
or
```
./build.sh -d mate -r release
```

#### (Option) To build GhostBSD development __MATE__ desktop iso
```
./build.sh
```
or 
```
./build.sh -d mate -r devel
```

## Burn an image to cd:
```
cdrecord /usr/local/ghostbsd-build/iso/GhostBSD-20.04.iso
```

## Write an image to usb stick:
```
dd if=/usr/local/ghostbsd-build/iso/GhostBSD-20.04.iso of=/dev/da0 bs=4m
```
