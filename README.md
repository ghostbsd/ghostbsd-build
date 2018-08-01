ghostbsd-build
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is quickly generate live images for GhostBSD.

## Features
* Build GhostBSD with FreeBSD and TrueOS
* Mate and XFCE desktop environments
* Hybrid DVD/USB image
* Compatible with VirtualBox, and VMware
* NVIDIA graphics driver

## System Requirements
* FreeBSD, TrueOS, GhostBSD for AMD64
* 20GB of free disk space
* 4GB of free memory
* UFS, or ZFS

## Initial Setup
Install the required packages:
```
pkg install git grub2-pcbsd grub2-efi xorriso
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
