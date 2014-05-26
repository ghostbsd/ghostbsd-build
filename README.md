ghostbsd-build
==============

Tool to build GhostBSD image.

The GhostBSD toolkit has been designed to allow building of both, i386 and amd64 architectures
on amd64 architectures. However, in order to build the packages for a specific environment, 
the packaging process must take place on this exact environment (so amd64 packages can only be 
built on amd64 environment and i386 packages - on i386).

First, you need to download the newest version of FreeBSD here - at this point you will be
interested in 9.0 release series. Install it on your building machine, ensuring that during the 
installation process, you choose the src and port packages. These are crucial for the building 
process. If you are planning to build packages from sources, please make sure you’ve dedicated 
a solid amount of disk space to swap (I suggest at least 4GB, especially on a amd64 machine).

After installing and setting up the building environment (make sure all your hardware has been 
more or less properly recognized - you will need quite some processing power, especially if you 
intend to build from ports).

First thing to do is download the newest version of the GhostBSD toolkit. The best way to do it 
so is via subversion (svn). It is not included by default on your new FreeBSD machine - to 
install it you must issue one of the following commands:

   pkg_add -r git

or

   cd /usr/ports/devel/git && make install clean

this one has to be done after fetching the ports tree, which you can do with:

   portsnap fetch update

I strongly suggest downloading the toolkit itself to /src

   cd /usr

and then

    git clone https://github.com/GhostBSD/ghostbsd-build.git 

Once svn checkout completes, you will have the whole GhostBSD development environment available 
on your machine locally. Time to do some preliminary configuration!
[edit] Preliminary configuration

First, you need to make some changes in fstab and rc.conf (using your favourite editor - we are 
going to be using ee here)

   ee /etc/fstab

add the following lines to the file:

   proc /proc procfs rw 0 0
   linproc /compat/linux/proc linprocfs rw 0 0

Make sure to create /compat/linux/proc directory before proceeding.

   mkdir -p /compat/linux/proc

Now mount linproc and proc

   mount linproc
   mount proc

Edit rc.conf

   ee /etc/rc.conf

Add the following settings to the file:

   gnome_enable="YES"
   hald_enable="YES"
   dbus_enable="YES"
   linux_enable="YES"

Reboot your machine.

Your development environment is now ready for building the packages.
[edit] Building the packages

Change directory to the GhostBSD tools directory:

   cd /usr/2.5-RC/tool

At this point, you can choose to build using packages or ports. The choice is yours to make and 
there are different reasons for either. Usually, you would consider the points made in the 
FreeBSD Handbook (http://www.freebsd.org/doc/en/books/handbook/ports-overview.html) but keep in 
mind you are building a reusable environment, possibly for others as well, so it is very 
important to choose more generic options (well provided in the package distribution system of 
FreeBSD).

Again, you will only be able to build for amd64 on an amd64 installation of FreeBSD. If you 
wish to build 32 bit media, you need to use an i386 installation of the system.

To install software from ports, run:

   sh portinstall.sh

For packages, run:

   sh pkginstall.sh

At this point you can also add the software of your own (as the script above only handles the 
crucial GhostBSD parts). You can do it by installing the software either from packages or 
ports, like with the standard installation on a FreeBSD machine.

After the installation of all packages completes, you need to pack your software:

   sh make_allpkg.sh

Now we are ready to configure and build the system.
[edit] Configuring the system

Have a look in /usr/2.5-RC/conf/ghostbsd.defaults.conf - you will notice very important lines 
below:

   NO_BUILDWORLD=YES

   NO_BUILDKERNEL=YES

Comment these two lines the first time you run the building process. The next time you run it, 
you can uncomment them - it will then save you quite some time (you simply do not need to 
rebuild your kernel and world every time unless you’ve committed significant changes to them).

There are many other options available for configuration in ghostbsd.defaults.conf.

   ARCH="amd64"

means that you are building the amd64 system. If you want to build for i386, change it as below:

   ARCH="i386"

You can also choose, whether to build GNOME or LXDE:

   PACK_PROFILE=${PACK_PROFILE:-"lxde"}
   PACK_PROFILE=${PACK_PROFILE:-"gnome"}

[edit] Building the system

Now that the whole configuration is done, all you need to push the button:

   cd /usr/2.5-RC
   make

This will build the whole system and the .iso image. To build the USB .img, you will 
additionally want to issue the below commands:


   make img

Now all we need to do is clean up after building (remember you can only build back after 
issuing the below commands):

   sudo make clean cleandir
