ghostbsd-build
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is quickly generate live images for GhostBSD.

## Features
* Build GhostBSD with FreeBSD and TrueOS
* Mate and XFCE desktop environments
* Hybrid DVD/USB image

## Graphics Support
* Compatible with VirtualBox, VMware, NVIDIA graphics out of box
* SCFB support with automatic best resolution for UEFI enabled systems with Intel/AMD graphics

## System Requirements
* TrueOS 18.06 or GhostBSD 18 for AMD64
* 20GB of free disk space
* 4GB of free memory

Note: GhostBSD 11.1, and earlier releases, cannot be used to build ISO.

## Initial Setup
Install the required packages:
```
pkg install git
```
Clone the repo:
```
git clone https://www.github.com/ghostbsd/ghostbsd-build.git
```
Enter the directory for running the LiveCD creator:
```
cd ghostbsd
```

## TrueOS base GhostBSD
```
./build trueos
./build trueos mate
./build trueos xfce
```

## FreeBSD base GhostBSD
```
./build freebsd
./build freebsd mate
./build freebsd xfce
```

## Burn an image to cd:
```
cdrecord /usr/local/ghostbsd-build/ghostbsd/GhostBSD18.08.iso
```

## Write an image to usb stick:
```
dd if=/usr/local/ghostbsd-build/ghostbsd/GhostBSD18.08.iso of=/dev/da0 bs=4m
```
