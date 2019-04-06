ghostbsd-build
==============
Live media creator for GhostBSD distribution

## Introduction
The purpose of this tool is quickly generate live images for GhostBSD.

## Features
* Build GhostBSD with GhostBSD or TrueOS
* Mate and XFCE desktop environments
* Hybrid DVD/USB image

## Graphics Support
* Compatible with VirtualBox, VMware, NVIDIA graphics out of box
* SCFB support with automatic best resolution for UEFI enabled systems with Intel/AMD graphics

## System Requirements
* Latest version of GhostBSD or TrueOS 
* 20GB of free disk space
* 4GB of free memory

Note: GhostBSD 18.06 and earlier releases cannot be used to build ISO.

## Initial Setup
Install the required packages:
```
pkg install git
```
Clone the repo:
```
git clone https://www.github.com/ghostbsd/ghostbsd-build.git
```
Enter the directory for running the LiveCD build script:
```
cd ghostbsd
```

## TrueOS base GhostBSD
To build a GhostBSD with MATE as default desktop
```
./build trueos mate
```   
(Option) To build GhostBSD with xfce as default desktop
```
./build trueos xfce
```   
(Option) To build GhostBSD without a default desktop
```
./build trueos
```    

## Burn an image to cd:
```
cdrecord /usr/local/ghostbsd-build/ghostbsd/GhostBSD18.12.iso
```

## Write an image to usb stick:
```
dd if=/usr/local/ghostbsd-build/ghostbsd/GhostBSD18.12.iso of=/dev/da0 bs=4m
```
