ghostbsd-build
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is quickly generate live images for GhostBSD.

## Features
* Build GhostBSD with FreeBSD and TrueOS
* AMD64
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

## FreeBSD base GhostBSD
```
./build freeghost
./build freeghost mate
./build freeghost xfce
```

## TrueOS base GhostBSD
```
./build trueghost
./build trueghost mate
./build trueghost xfce
```

## Burn an image to cd:
```
cdrecord /usr/local/ghostbsd-build/ghostbsd/ghostbsd-mate.iso
```

## Write an image to usb stick:
```
dd if=/usr/local/ghostbsd-build/ghostbsd/ghostbsd-mate.iso of=/dev/da0 bs=4m
```


