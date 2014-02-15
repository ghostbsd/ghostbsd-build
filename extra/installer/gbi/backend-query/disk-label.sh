#!/bin/sh
# Query a disk for partitions and display them
#############################


DISK="${1}"
TMPDIR=${TMPDIR:-"/tmp"}
# Display if this is GPT or MBR formatted
gpart show ${1} | grep "GPT" >/dev/null 2>/dev/null
if [ "$?" = "0" ] ; then
    #echo "${1}-format: GPT"
    TYPE="GPT"
else
    #echo "${1}-format: MBR"
    TYPE="MBR"
fi

if [ "$TYPE" = "MBR" ] ; then
    sp="s"
else
    sp="p"
fi

# Get a listing of partitions on this disk
gpart show ${DISK} | grep -v ${DISK} | tr -s '\t' ' ' | cut -d ' ' -f 4,3,5 >${TMPDIR}/disk-${DISK}
while read i
do

    if [ ! -z "${i}" ] ; then
        BLOCK="`echo ${i} | cut -d ' ' -f 1`"
        MB="`expr ${BLOCK} / 2048`MB"
    fi
    if [ ! "${MB}" = "0MB" ] ; then
        LABEL="`echo ${i} | cut -d ' ' -f 3`"
        SLICE="`echo ${i} | cut -d ' ' -f 2`"
        if [ "$SLICE" = '-' ] ; then
            echo "freespace  ${MB}"
        else
            if [ ! -z "$SLICE" ] ; then
                echo "${MB} ${LABEL}"
            fi
        fi
    fi

done <${TMPDIR}/disk-${DISK}
