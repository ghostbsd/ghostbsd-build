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
  cat ${cwd}/packages/lumina | xargs pkg-static -c ${release} install -y
  cat ${cwd}/packages/mate | xargs pkg-static -c ${release} install -y 
  rm ${release}/etc/resolv.conf
}

rc()
{
  chroot ${release} /sbin/rc-update -u 
}

user()
{
  chroot ${release} pw useradd liveuser \
  -c "Live User" -d "/home/liveuser" \
  -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
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
	install -o root -g wheel -m 644 "grub.cfg" "${cdroot}/boot/grub"
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
