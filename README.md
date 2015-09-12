ghostbsd-build
==============
## Introduction
GhostBSD build toolkit is directly derivated from FreeSBIE toolkit, but most of the code changed.The ghostbsd-build is been designed to allow developers to building both, i386 and amd64 architectures on amd64 architectures. The ghostbsd-build to can build GhostBSD on FreeBSD, PCBSD and GhostBSD.
## Installing ghostbsd-build
First, you need to install git as root user using su or sudo.
```
pkg install git
```
Second thing is to download GhostBSD Build Toolkit.
```
git clone https://github.com/GhostBSD/ghostbsd-build.git
```

## Configuring the system

Have a look in ghostbsd-build/conf/ghostbsd.defaults.conf - you will notice very important lines 
below:
```
   NO_BUILDWORLD=YES
   NO_BUILDKERNEL=YES
```
Comment these two lines the first time you run the building process for each Architectures. The next time you run it, 
you can uncomment them - it will then save you quite some time (you simply do not need to 
rebuild your kernel and world every time unless you’ve committed significant changes to them).

## Building the system

Now that the whole configuration is done, all you need to push the button:

   cd ghostbsd-build/mkscripts

This will build the whole system and the .iso image. To build the USB .img, you will 
additionally want to issue the below commands:


   make img

Now all we need to do is clean up after building (remember you can only build back after 
issuing the below commands):

   sudo make clean cleandir
