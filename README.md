ghostbsd-build
==============
## Introduction
The GhostBSD build toolkit is directly derived from the _FreeSBIE_ toolkit, but most of the code has been changed. Ghostbsd-build has been 
designed to allow developers to build both __i386__ and __amd64__ ISO images on __amd64__ systems. Ghostbsd-build can build GhostBSD on 
__FreeBSD__, __PC-BSD__ and __GhostBSD__.
## Installing ghostbsd-build
First, you need to install __git__ as root user using either su or sudo (or logging in directly as root). Also the packages __grub2-pcbsd__ 
and __xorriso__ are required:
```
pkg install git grub2-pcbsd grub2-efi xorriso rsync
```
Second is to download the GhostBSD Build Toolkit.
```
git clone https://github.com/GhostBSD/ghostbsd-build.git
```

## Configuring the system

Have a look at _ghostbsd-build/conf/ghostbsd.defaults.conf_ - you will notice the very important lines below:
```
   NO_BUILDWORLD=YES
   NO_BUILDKERNEL=YES
```

Comment out these two lines the first time you run the building process for each architecture. The next time you run it, 
you can uncomment them - this will save you quite some build time (you simply do not need to rebuild your kernel and world every time 
unless you've committed significant changes to them).

If you would like avoid compiling the kernel and world, you can fetch the FreeBSD files to build from. This is a faster and cleaner way. 
To enable this, make sure that your _ghostbsd-build/conf/ghostbsd.defaults.conf_ has the following lines enabled:
```
   FETCH_FREEBSDBASE=${FETCH_FREEBSDBASE:-"YES"}
   FETCH_FREEBSDKERNEL=${FETCH_FREEBSDKERNEL:-"YES"}
```
By default ghostbsd-build is configured to work out of the box.

## Building the system

After the configuration is done, all you need is to push the button. Go to the mkscripts directory first:
```
cd ghostbsd-build/mkscripts
```   
Now you will need to execute one of the following scripts in this directory. E.g. to build __MATE__ for __amd64__ run:
```
./make_mate_amd64_iso
```
This will build the whole system and create the ISO image. 

Once the process is finished, it's a good idea to clean up the system after building. The example below shows the script to clean for __MATE__ on __amd64__. 
(remember you can only rebuild after cleaning up using the following commands):
```
cd ghostbsd-build/clscripts
./clean_mate_amd64
```
