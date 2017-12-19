#!/bin/sh
#
# Copyright (c) 2005 Dario Freni
#
# See COPYING for licence terms.
#
# $FreeBSD$
# $Id: installkernel.sh,v 1.8 2006/10/01 12:00:47 drizzt Exp $

set -e -u

if [ -z "${LOGFILE:-}" ]; then
    echo "This script can't run standalone."
    echo "Please use launch.sh to execute it."
    exit 1
fi

jail_name=${PACK_PROFILE}${ARCH}

install_built_kernel()
{
echo "#### Installing kernel for ${ARCH} architecture ####"

# Set MAKE_CONF variable if it's not already set.
if [ -z "${MAKE_CONF:-}" ]; then
    if [ -n "${MINIMAL:-}" ]; then
	MAKE_CONF=${LOCALDIR}/conf/make.conf.minimal
    else
	MAKE_CONF=${LOCALDIR}/conf/make.conf
    fi
fi

if [ -n "${KERNELCONF:-}" ]; then
    export KERNCONFDIR=$(dirname ${KERNELCONF})
    export KERNCONF=$(basename ${KERNELCONF})
elif [ -z "${KERNCONF:-}" ]; then
    export KERNCONFDIR=${LOCALDIR}/conf/${ARCH}
    export KERNCONF="GENERIC"
fi

mkdir -p ${BASEDIR}/boot
cp ${SRCDIR}/sys/${ARCH}/conf/GENERIC.hints ${BASEDIR}/boot/device.hints
echo hint.psm.0.flags=0x1000 >> ${BASEDIR}/boot/device.hints

cd ${SRCDIR}

makeargs="${MAKEOPT:-} ${MAKEJ_KERNEL:-} __MAKE_CONF=${MAKE_CONF} TARGET_ARCH=${ARCH} DESTDIR=${BASEDIR} SRCCONF=${SRC_CONF}"
(env $MAKE_ENV script -aq $LOGFILE make ${makeargs:-} installkernel || print_error;) | grep '^>>>'

#cd ${BASEDIR}/boot/kernel
#if [ "${ARCH}" = "$(uname -p)" -a -z "${DEBUG:-}" ]; then
#    strip kernel
#fi

#gzip -f9 kernel
}

install_fetched_kernel()
{
echo "#### Installing kernel for ${ARCH} architecture ####" | tee -a ${LOGFILE}
cd ${CACHEDIR}
tar -yxf kernel.txz -C ${BASEDIR} --exclude=\*\.symbols
}

update_freebsd()
{
cp /etc/resolv.conf ${BASEDIR}/etc
cat > ${BASEDIR}/fbsdupdate.conf << 'EOF'
# $FreeBSD: releng/10.1/etc/freebsd-update.conf 258121 2013-11-14 09:14:33Z glebius $

# Trusted keyprint.  Changing this is a Bad Idea unless you've received
# a PGP-signed email from <security-officer@FreeBSD.org> telling you to
# change it and explaining why.
KeyPrint 800651ef4b4c71c27e60786d7b487188970f4b4169cc055784e21eb71d410cc5

# Server or server pool from which to fetch updates.  You can change
# this to point at a specific server if you want, but in most cases
# using a "nearby" server won't provide a measurable improvement in
# performance.
ServerName update.FreeBSD.org

# Components of the base system which should be kept updated.
Components  kernel world

# Example for updating the userland and the kernel source code only:
# Components src/base src/sys world

# Paths which start with anything matching an entry in an IgnorePaths
# statement will be ignored.
IgnorePaths

# Paths which start with anything matching an entry in an IDSIgnorePaths
# statement will be ignored by "freebsd-update IDS".
IDSIgnorePaths /usr/share/man/cat
IDSIgnorePaths /usr/share/man/whatis
IDSIgnorePaths /var/db/locate.database
IDSIgnorePaths /var/log

# Paths which start with anything matching an entry in an UpdateIfUnmodified
# statement will only be updated if the contents of the file have not been
# modified by the user (unless changes are merged; see below).
UpdateIfUnmodified /etc/ /var/ /root/ /.cshrc /.profile

# When upgrading to a new FreeBSD release, files which match MergeChanges
# will have any local changes merged into the version from the new release.
MergeChanges /etc/ /boot/device.hints

### Default configuration options:

# Directory in which to store downloaded updates and temporary
# files used by FreeBSD Update.
# WorkDir /var/db/freebsd-update

# Destination to send output of "freebsd-update cron" if an error
# occurs or updates have been downloaded.
# MailTo root

# Is FreeBSD Update allowed to create new files?
AllowAdd yes

# Is FreeBSD Update allowed to delete files?
AllowDelete yes

# If the user has modified file ownership, permissions, or flags, should
# FreeBSD Update retain this modified metadata when installing a new version
# of that file?
# KeepModifiedMetadata yes

# When upgrading between releases, should the list of Components be
# read strictly (StrictComponents yes) or merely as a list of components
# which *might* be installed of which FreeBSD Update should figure out
# which actually are installed and upgrade those (StrictComponents no)?
# StrictComponents no

# When installing a new kernel perform a backup of the old one first
# so it is possible to boot the old kernel in case of problems.
 BackupKernel no

# If BackupKernel is enabled, the backup kernel is saved to this
# directory.
# BackupKernelDir /boot/kernel.old

# When backing up a kernel also back up debug symbol files?
# BackupKernelSymbolFiles no
EOF

freebsd-update  -b ${BASEDIR} -f ${BASEDIR}/fbsdupdate.conf --not-running-from-cron fetch install
rm -f ${BASEDIR}/etc/resolv.conf
rm -f ${BASEDIR}/fbsdupdate.conf
}

if [ -n "${FETCH_FREEBSDKERNEL:-}" ]; then
    install_fetched_kernel
     #if $JAIL_RESTART ; then
        #update_freebsd
     #fi
else
    install_built_kernel
fi

# fix missing linker.hints from /boot/kernel
if [ "${ARCH}" = "i386" ] ; then
    chrootcmd="chroot ${BASEDIR} kldxref /boot/kernel /boot/modules"
    $chrootcmd
fi

set -e
cd $LOCALDIR
