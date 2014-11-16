#!/usr/bin/env python
#
# Copyright (c) 2013 GhostBSD
#
# See COPYING for licence terms.
#
# create_cfg.py v 1.4 Friday, January 17 2014 Eric Turgeon
#

import os
import pickle
from subprocess import Popen

# Directory use from the installer.
tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
start_Install = 'python %sinstall.py' % installer
# Installer data file.
disk = '%sdisk' % tmp
layout = '%slayout' % tmp
model = '%smodel' % tmp
pcinstallcfg = '%spcinstall.cfg' % tmp
user_passwd = '%suser' % tmp
language = '%slanguage' % tmp
dslice = '%sslice' % tmp
left = '%sleft' % tmp
partlabel = '%spartlabel' % tmp
timezone = '%stimezone' % tmp
variant = '%svariant' % tmp
boot_file = '%sboot' % tmp
disk_schem = '%sscheme' % tmp


class cfg_data():
    f = open('%spcinstall.cfg' % tmp, 'w')
    # Installation Mode
    f.writelines('# Installation Mode\n')
    f.writelines('installMode=fresh\n')
    f.writelines('installInteractive=no\n')
    f.writelines('installType=GhostBSD\n')
    f.writelines('installMedium=dvd\n')
    f.writelines('packageType=livecd\n')
    # System Language
    lang = open(language, 'r')
    l_output = lang.readlines()[0].strip().partition(':')[2].strip()
    f.writelines('\n# System Language\n')
    f.writelines('localizeLang=%s\n' % l_output)
    os.remove(language)
    # Keyboard Setting
    if os.path.exists(model):
        f.writelines('\n# Keyboard Setting\n')
        os.remove(model)
    if os.path.exists(layout):
        lay = open(layout, 'r')
        l_output = lay.readlines()[0].strip().partition('-')[2].strip()
        f.writelines('localizeKeyLayout=%s\n' % l_output)
        os.remove(layout)
    if os.path.exists(variant):
        var = open(variant, 'r')
        v_output = var.readlines()[0].strip().partition(':')[2].strip()
        f.writelines('localizeKeyVariant=%s\n' % v_output)
        os.remove(variant)
    # Timezone
    if os.path.exists(timezone):
        time = open(timezone, 'r')
        t_output = time.readlines()[0].strip()
        f.writelines('\n# Timezone\n')
        f.writelines('timeZone=%s\n' % t_output)
        #f.writelines('enableNTP=yes\n')
        os.remove(timezone)
    # Disk Setup
    r = open(disk, 'r')
    drive = r.readlines()
    d_output = drive[0].strip()
    f.writelines('\n# Disk Setup\n')
    f.writelines('disk0=%s\n' % d_output)
    os.remove(disk)
    # Partition Slice.
    p = open(dslice, 'r')
    line = p.readlines()
    part = line[0].rstrip()
    f.writelines('partition=%s\n' % part)
    os.remove(dslice)
    # Boot Menu
    read = open(boot_file, 'r')
    line = read.readlines()
    boot = line[0].strip()
    f.writelines('bootManager=%s\n' % boot)
    os.remove(boot_file)
    # Sheme sheme
    read = open(disk_schem, 'r')
    shem = read.readlines()[0]
    f.writelines(shem + '\n')
    f.writelines('commitDiskPart\n')
    os.remove(disk_schem)
    # Partition Setup
    f.writelines('\n# Partition Setup\n')
    part = open(partlabel, 'r')
    # If slice and auto file exist add first partition line.
    # But Swap need to be 0 it will take the rest of the freespace.
    for line in part:
        if 'BOOT' in line:
            pass
        else:
            f.writelines('disk0-part=%s\n' % line.strip())
    f.writelines('commitDiskLabel\n')
    os.remove(partlabel)
    # Network Configuration
    f.writelines('\n# Network Configuration\n')
    readu = open(user_passwd, 'rb')
    uf = pickle.load(readu)
    net = uf[5]
    f.writelines('hostname=%s\n' % net)
    # Set the root pass
    f.writelines('\n# Network Configuration\n')
    readr = open('%sroot' % tmp, 'rb')
    rf = pickle.load(readr)
    root = rf[0]
    f.writelines('\n# Set the root pass\n')
    f.writelines('rootPass=%s\n' % root)
    # Setup our users
    user = uf[0]
    f.writelines('\n# Setup user\n')
    f.writelines('userName=%s\n' % user)
    name = uf[1]
    f.writelines('userComment=%s\n' % name)
    passwd = uf[2]
    f.writelines('userPass=%s\n' % passwd.rstrip())
    shell = uf[3]
    f.writelines('userShell=%s\n' % shell)
    upath = uf[4]
    f.writelines('userHome=%s\n' % upath.rstrip())
    f.writelines('defaultGroup=wheel')
    f.writelines('userGroups=operator\n')
    f.writelines('commitUser\n')
    f.writelines('runCommand=iso_to_hd')
    f.close()
    os.remove(user_passwd)
    Popen(start_Install, shell=True)

cfg_data()
