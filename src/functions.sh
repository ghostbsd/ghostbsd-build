#!/usr/bin/env sh

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# We must choose a desktop
desktop=$1
if [ -z "${desktop}" ] ; then
  echo "You must specify a desktop!"
  echo "Choices are lumina, mate, xfce"
  echo "Usage: build.sh mate"
fi

case $desktop in
     lumina) 
            export desktop="lumina";;
       mate) 
            export desktop="mate";;
       xfce) 
            export desktop="xfce";;
          *)
            echo "${desktop} is not a supported desktop!"
	    echo "Choices are lumina, mate, xfce"	
	    echo "Usage: build.sh mate"
	    exit 1
esac

# Source our config
. build.cfg

# Set the current working directory
cwd="`realpath | sed 's|/scripts||g'`" ; export cwd

workspace()
{
  if [ -d "${livecd}" ] ;then
    chflags -R noschg ${livecd} >/dev/null 2>/dev/null
    rm -rf ${livecd} >/dev/null 2>/dev/null
  fi
  if [ ! -d "${livecd}" ] ; then
    mkdir ${livecd} ${base} ${packages}
  fi
}

repos()
{
  cp -R ${cwd}/repos/ ${release}
}

base()
{
  cd ${base}
  fetch http://download.trueos.org/master/amd64/dist/base.txz
  fetch http://download.trueos.org/master/amd64/dist/kernel.txz
  tar -zxvf ${base}/base.txz -C ${release}
  tar -zxvf ${base}/kernel.txz -C ${release}
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  pkg-static -c ${release} update -r trueos-base
  pkg-static -c ${release} install -y -g 'FreeBSD-*'
}

packages()
{
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  case $desktop in
  	lumina) 
	       cat ${cwd}/packages/lumina | xargs pkg-static -c ${release} install -y ;;
  	  mate)
	       cat ${cwd}/packages/mate | xargs pkg-static -c ${release} install -y ;;
  	  xfce) 
	       cat ${cwd}/packages/xfce | xargs pkg-static -c ${release} install -y ;;
  	     *) 
	       exit 1
  esac
  pkg-static -c ${release} clean -a -y
  rm ${release}/etc/resolv.conf
}

rc()
{
  case $desktop in
  lumina)
  	 chroot ${release} /sbin/rc-update add trueos-video default
  	 chroot ${release} /sbin/rc-update -u ;;
    mate)
	 chroot ${release} /sbin/rc-update add moused boot
	 chroot ${release} /sbin/rc-update add dbus default
	 chroot ${release} /sbin/rc-update add hald default
	 chroot ${release} /sbin/rc-update add pcdm default
	 chroot ${release} /sbin/rc-update add trueos-video default
         chroot ${release} /sbin/rc-update -u ;;	
    xfce)
  	 chroot ${release} /sbin/rc-update add moused boot
	 chroot ${release} /sbin/rc-update add dbus default
	 chroot ${release} /sbin/rc-update add hald default
	 chroot ${release} /sbin/rc-update add pcdm default
	 chroot ${release} /sbin/rc-update add trueos-video default
	 chroot ${release} /sbin/rc-update -u ;;
       *)
	 exit 1
  esac
}

user()
{
  chroot ${release} pw useradd liveuser \
  -c "Live User" -d "/home/liveuser" \
  -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
}

xorg()
{
  install -o root -g wheel -m 755 "${cwd}/xorg/bin/trueos-video" "${release}/usr/local/bin/"
  install -o root -g wheel -m 755 "${cwd}/xorg/init.d/trueos-video" "${release}/usr/local/etc/init.d/"
  if [ ! -d "${release}/usr/local/etc/X11/cardDetect/" ] ; then
    mkdir -p ${release}/usr/local/etc/X11/cardDetect
  fi
  install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.vesa" "${release}/usr/local/etc/X11/cardDetect/"
  install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.scfb" "${release}/usr/local/etc/X11/cardDetect/"
  install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.virtualbox" "${release}/usr/local/etc/X11/cardDetect/"
}

uzip() 
{
	install -o root -g wheel -m 755 -d "${cdroot}"
	mkdir "${cdroot}/data"
	makefs "${cdroot}/data/system.ufs" "${release}"
	mkuzip -o "${cdroot}/data/system.uzip" "${cdroot}/data/system.ufs"
	rm -f "${cdroot}/data/system.ufs"
}

ramdisk() 
{
	ramdisk_root="${cdroot}/data/ramdisk"
	mkdir -p "${ramdisk_root}"
	cd "${release}"
	tar -cf - rescue | tar -xf - -C "${ramdisk_root}"
	cd "${cwd}"
	install -o root -g wheel -m 755 "init.sh.in" "${ramdisk_root}/init.sh"
	sed "s/@VOLUME@/${vol}/" "init.sh.in" > "${ramdisk_root}/init.sh"
	mkdir "${ramdisk_root}/dev"
	mkdir "${ramdisk_root}/etc"
	touch "${ramdisk_root}/etc/fstab"
	makefs -b '10%' "${cdroot}/data/ramdisk.ufs" "${ramdisk_root}"
	gzip "${cdroot}/data/ramdisk.ufs"
	rm -rf "${ramdisk_root}"
}

boot() 
{
	cd "${release}"
	tar -cf - --exclude boot/kernel boot | tar -xf - -C "${cdroot}"
	for kfile in kernel geom_uzip.ko nullfs.ko tmpfs.ko unionfs.ko; do
		tar -cf - boot/kernel/${kfile} | tar -xf - -C "${cdroot}"
	done
	cd "${cwd}"
	install -o root -g wheel -m 644 "loader.conf" "${cdroot}/boot/"
	if [ ! -d "${cdroot}/boot/grub" ] ; then
          mkdir ${cdroot}/boot/grub
        fi
	install -o root -g wheel -m 644 "grub.cfg" "${cdroot}/boot/grub/"
}

image() 
{
  cat << EOF >/tmp/xorriso
ARGS=\`echo \$@ | sed 's|-hfsplus ||g'\`
xorriso \$ARGS
EOF
  chmod 755 /tmp/xorriso
  grub-mkrescue --xorriso=/tmp/xorriso -o ${livecd}/ghostbsd.iso ${cdroot} -- -volid ${vol}
}
