#!/bin/sh

# Need access to a some unmount functions
. ${PROGDIR}/backend/functions-unmount.sh

echo "Running: find-update-parts" >> ${LOGOUT}

rm ${TMPDIR}/AvailUpgrades >/dev/null 2>/dev/null

FSMNT="/mnt"

# Get the freebsd version on this partition
get_fbsd_ver() {

  VER="`file ${FSMNT}/bin/sh | grep 'for FreeBSD' | sed 's|for FreeBSD |;|g' | cut -d ';' -f 2 | cut -d ',' -f 1`"
  if [ "$?" = "0" ] ; then
      file ${FSMNT}/bin/sh | grep '32-bit' >/dev/null 2>/dev/null
      if [ "${?}" = "0" ] ; then
        echo "${1}: FreeBSD ${VER} (32bit)"
      else
        echo "${1}: FreeBSD ${VER} (64bit)"
      fi
  fi

}

# Create our device listing
SYSDISK="`sysctl kern.disks | cut -d ':' -f 2 | sed 's/^[ \t]*//'`"
DEVS=""

# Now loop through these devices, and list the disk drives
for i in ${SYSDISK}
do

  # Get the current device
  DEV="${i}"
  # Make sure we don't find any cd devices
  echo "${DEV}" | grep -e "^acd[0-9]" -e "^cd[0-9]" -e "^scd[0-9]" >/dev/null 2>/dev/null
  if [ "$?" != "0" ] ; then
   DEVS="${DEVS} `ls /dev/${i}*`" 
  fi

done

# Search for regular UFS / Geom Partitions to upgrade
for i in $DEVS
do
    if [ ! -e "${i}a.journal" -a ! -e "${i}a" -a ! -e "${i}p2" -a ! -e "${i}p2.journal" ] ; then
	continue
    fi

    if [ -e "${i}a.journal" ] ; then
	_dsk="${i}a.journal" 
    elif [ -e "${i}a" ] ; then
	_dsk="${i}a" 
    elif [ -e "${i}p2" ] ; then
	_dsk="${i}p2" 
    elif [ -e "${i}p2.journal" ] ; then
	_dsk="${i}p2.journal" 
    fi

   mount ${_dsk} ${FSMNT} >>${LOGOUT} 2>>${LOGOUT}
   if [ "${?}" = "0" -a -e "${FSMNT}/bin/sh" ] ; then
    	get_fbsd_ver "`echo ${_dsk} | sed 's|/dev/||g'`"
        umount -f ${FSMNT} >/dev/null 2>/dev/null
   fi
done

# Now search for any ZFS root partitions
zpool import -o altroot=${FSMNT} -a

# Unmount any auto-mounted stuff
umount_all_dir "${FSMNT}"

# Get pools
_zps="`zpool list | grep -v 'NAME' | cut -d ' ' -f 1`"
for _zpools in ${_zps}
do
   mount -t zfs ${_zpools} ${FSMNT} >>${LOGOUT} 2>>${LOGOUT}
   if [ "${?}" = "0" -a -e "${FSMNT}/bin/sh" ] ; then
    	get_fbsd_ver "${_zpools}"
        umount -f ${FSMNT} >/dev/null 2>/dev/null
   fi
done
