#!/bin/sh
# Query a disk for partitions and display them
#############################


if [ -z "${1}" ]
then
  echo "Error: No disk specified!"
  exit 1
fi

if [ ! -e "/dev/${1}" ]
then
  echo "Error: Disk /dev/${1} does not exist!"
  exit 1
fi

# Function to convert bytes to megabytes
convert_byte_to_megabyte()
{
  if [ -z "${1}" ]
  then
    echo "Error: No bytes specified!"
    exit 1
  fi

  expr -e ${1} / 1048576
};

# Function which returns a target disks cylinders
get_disk_cyl()
{
  cyl=`diskinfo -v ${1} | grep "# Cylinders" | tr -s ' ' | cut -f 2`
  export VAL="${cyl}"
};
DISK="${1}"

# Function which returns a target disks heads
get_disk_heads()
{
  head=`diskinfo -v ${1} | grep "# Heads" | tr -s ' ' | cut -f 2`
  export VAL="${head}"
};

# Function which returns a target disks sectors
get_disk_sectors()
{
  sec=`diskinfo -v ${1} | grep "# Sectors" | tr -s ' ' | cut -f 2`
  export VAL="${sec}"
};

get_disk_cyl "${DISK}"
CYLS="${VAL}"

get_disk_heads "${DISK}"
HEADS="${VAL}"

get_disk_sectors "${DISK}"
SECS="${VAL}"

#echo "cylinders=${CYLS}"
#echo "heads=${HEADS}"
#echo "sectors=${SECS}"

# Now get the disks size in MB
KB="`diskinfo -v ${1} | grep 'bytes' | cut -d '#' -f 1 | tr -s '\t' ' ' | tr -d ' '`"
MB=$(convert_byte_to_megabyte ${KB})
#echo "size=$MB"
echo "$MB"
# Now get the Controller Type
CTYPE="`dmesg | grep "^${1}:" | grep "B <" | cut -d '>' -f 2 | cut -d ' ' -f 3-10`"
#echo "type=$CTYPE"
