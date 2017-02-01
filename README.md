ghostbsd-build
==============
## Introduction
GhostBSD build toolkit is directly derived from FreeSBIE toolkit, but most of the code changed.The ghostbsd-build is been designed to allow developers to building both, i386 and amd64 architectures on amd64 architectures. The ghostbsd-build to can build GhostBSD on FreeBSD, PCBSD and GhostBSD.
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

If you would like avoid compiling GhostBSD you can fetch the freebsd file to build and this faster and cleaner make sure that your ghostbsd-build/conf/ghostbsd.defaults.conf have these to lines below:
```
FETCH_FREEBSDBASE=${FETCH_FREEBSDBASE:-"YES"}
FETCH_FREEBSDKERNEL=${FETCH_FREEBSDKERNEL:-"YES"}
```
By default ghostbsd-build is configure to work out of the box.

## Building the system

Now that the whole configuration is done, all you need to push the button:

   cd ghostbsd-build/mkscripts
   
Now you will need to execute one of the following scripts in this directory.  To build mate for amd64:

   ./make_mate_amd64_iso

This will build the whole system and the .iso image. 

Now all we need to do is clean up after building.  The example below shows the script to clean for Mate on AMD64.  (remember you can only rebuild after issuing the following commands):

   cd ghostbsd-build/clscripts
   clean_mate_amd64
