#!/usr/bin/env sh

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

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
  pkg-static -c ${release} install -y trueos-desktop 
  rm ${release}/etc/resolv.conf
}


repos()
{
  cp -R ${cwd}/repos/ ${release}
}

user()
{
GHOSTBSD_USER="ghostbsd"
grep -q ^${GHOSTBSD_USER}: ${release}/etc/master.passwd

if [ $? -ne 0 ]; then
    chroot ${release} pw useradd ${GHOSTBSD_USER} \
         -c "Live User" -d "/home/${GHOSTBSD_USER}" \
        -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
else
    chroot ${release} pw usermod ${GHOSTBSD_USER} \
        -c "Live User" -d "/home/${GHOSTBSD_USER}" \
        -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
fi
}

uzip () 
{
	install -o root -g wheel -m 755 -d "${cdroot}"
	mkdir "${cdroot}/data"
	makefs "${cdroot}/data/system.ufs" "${release}"
	mkuzip -o "${cdroot}/data/system.uzip" "${cdroot}/data/system.ufs"
	rm -f "${cdroot}/data/system.ufs"
}

ramdisk () 
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

boot () 
{
	cd "${release}"
	tar -cf - --exclude boot/kernel boot | tar -xf - -C "${cdroot}"
	for kfile in kernel geom_uzip.ko nullfs.ko tmpfs.ko unionfs.ko; do
		tar -cf - boot/kernel/${kfile} | tar -xf - -C "${cdroot}"
	done
	cd "${cwd}"
	install -o root -g wheel -m 644 "loader.conf" "${cdroot}/boot/"
}

image() 
{
  cd "${cdroot}"
  mkisofs -iso-level 4 -R -l -ldots -allow-lowercase -allow-multidot -V "GhostBSD" -o "/tmp/livecd/ghostbsd.iso" -no-emul-boot -b boot/cdboot .
}
