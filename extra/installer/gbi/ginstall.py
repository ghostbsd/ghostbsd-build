#!/usr/bin/env python
#
# Copyright (c) 2011 GhostBSD
#
# See COPYING for license terms.
#
# ginstall.py v 1.2 Friday, September  2012 12:27:53 Kamil Kajczynski

# importation of tool need.
import os
import os.path
from subprocess import Popen, PIPE, STDOUT, call
import getpass
from time import sleep

# Path need to the installer.
PATH = "/home/ghostbsd"
PC_SYS = "sudo pc-sysinstall"
CFG = "%s/pcinstall.cfg" % PATH
tmp = "/home/ghostbsd/.gbi"
installer = "/usr/local/etc/gbi/"
query = "sh /usr/local/etc/gbi/backend-query/"
if not os.path.exists(tmp):
    os.makedirs(tmp)
disk_part = '%sdisk-part.sh' % query
disk_label = '%sdisk-label.sh' % query
add_part = 'gpart add'
memory = 'sysctl hw.physmem'
disk_list = '%sdisk-list.sh' % query

FIN = """ Installation is complete. You need to restart the
 computer in order to use the new installation.
 You can continue to use this live CD, although
 any changes you make or documents you save will
 not be preserved on reboot."""

# Erasing the file after a restart of the installer.
if os.path.exists(CFG):
    os.remove(CFG)
if os.path.exists('%s/label' % PATH):
    os.remove('%s/label' % PATH)
if os.path.exists('%s/left' % PATH):
    os.remove('%s/left' % PATH)

#some commonly used pieces of text:

bootMenu = """  Boot manager option\n---------------------------------
  1: BSD boot Manager\n---------------------------------
  2: No boot manager\n---------------------------------"""


# The beginning of the installer.
class Ginstall:

    def __init__(self):
        call('clear', shell=True)
        cfg = open(CFG, 'w')
        cfg.writelines('installMode=fresh\n')
        cfg.writelines('installInteractive=no\n')
        cfg.writelines('installType=FreeBSD\n')
        cfg.writelines('installMedium=dvd\n')
        cfg.writelines('packageType=livecd\n')

    # choosing disk part.
        print ' Disk         Disk Name'
        p = Popen(disk_list, shell=True, stdout=PIPE, close_fds=True)
        for line in p.stdout:
            print '-----------------------------------'
            print ' %s' % line.rstrip()
            print '-----------------------------------'
        DISK = raw_input("\n\n Select a disk to install GhostBSD: ")
        cfg.writelines('disk0=%s\n' % DISK)

    # Install option part.
        while True:
            call('clear', shell=True)
            print '        Installation Options'
            print '---------------------------------------------'
            print ' 1: Use the entire disk %s' % DISK
            print '---------------------------------------------'
            print ' 2: Partition disk %s with auto labeling' % DISK
            print '---------------------------------------------'
            print ' 3: Customize disk %s partition (Advanced)' % DISK
            print '---------------------------------------------'
            INSTALL = raw_input('\n\nChoose an option(1, 2, 3): ')
            call('clear', shell=True)

    # First option: installing in the entire disk.
            if INSTALL == "1":
                while True:
                    # Boot manger selection
                    call('clear', shell=True)
                    print bootMenu
                    BOOT = raw_input('\n\nChose an option(1, 2): ')
                    if BOOT == '1':
                        BMANAGER = 'bootManager=bsd\n'
                        break
                    elif BOOT == '2':
                        BMANAGER = 'bootManager=none\n'
                        break
                    else:
                        print "Chose 1 or 2."
                        sleep(1)
                cfg.writelines('partition=all\n')
                cfg.writelines(BMANAGER)
                cfg.writelines('commitDiskPart\n')
                DINFO = '%sdisk-info.sh %s' % (query, DISK)
                p = Popen(DINFO, shell=True, stdout=PIPE, close_fds=True)
                for line in p.stdout:
                    NUMBER = int(line.rstrip())
                ram = Popen(memory, shell=True, stdout=PIPE, close_fds=True)
                mem = ram.stdout.read()
                SWAP = int(mem.partition(':')[2].strip()) / (1024 * 1024)
                ROOT = NUMBER - SWAP
                cfg.writelines('disk0-part=UFS %s /\n' % ROOT)
                cfg.writelines('disk0-part=SWAP 0 none\n')
                cfg.writelines('commitDiskLabel\n')
                break

    # Second option slice partition With auto labels.
            elif INSTALL == "2":
                while True:
                    call('clear', shell=True)
                    print bootMenu
                    BOOT = raw_input('\n\nChoose an option(1, 2): ')
                    if BOOT == '1':
                        BMANAGER = 'bootManager=bsd\n'
                        break
                    elif BOOT == '2':
                        BMANAGER = 'bootManager=none\n'
                        break
                    else:
                        print "Choose 1 or 2."
                        sleep(1)
                while True:
                    call('clear', shell=True)
                    print ' Slice        Size     System'
                    print '---------------------------------'
                    #print '---------------------------------'
                    DLIST = '%s %s' % (disk_part, DISK)
                    p = Popen(DLIST, shell=True, stdout=PIPE, close_fds=True)
                    for line in p.stdout:
                        #print '---------------------------------'
                        print ' %s' % line.rstrip()
                        print '---------------------------------'
                    DPART = raw_input("(d)elete (c)reate (n)ext: ")
                    if DPART == "d":
                        DELPART = raw_input('Select the slice to delete(s1, s2, s3 or s4): ')
                        call('gpart delete -i %s %s' % (DELPART[-1], DISK), shell=True)
                        #call('%s delete-part %s%s' % (PC_SYS, DISK, DELPART), shell=True)
                        print "delete " + DISK + DELPART
                    elif DPART == "c":
                        CPART = int(raw_input('Enter size of partition to create: '))
                        call('%s create-part %s %s' % (PC_SYS, DISK, CPART))
                    elif DPART == "n":
                        while True:
                            SLICE = raw_input("Select the slice you wish to install GhostBSD to (s1' s2' s3 or s4): ")
                            if SLICE == 's1' or SLICE == 's2' or SLICE == 's3' or SLICE == 's4':
                                cfg.writelines('partition=%s' % SLICE)
                                break
                        cfg.writelines(BMANAGER)
                        cfg.writelines('commitDiskPart\n')
                        PART = int(raw_input("Enter the size of partition %s%s: " % (DISK, SLICE)))
                        ram = Popen(memory, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
                        mem = ram.stdout.read()
                        SWAP = int(mem.partition(':')[2].strip()) / (1024 * 1024)
                        ROOT = PART - SWAP
                        cfg.writelines('disk0-part=UFS %s /\n' % ROOT)
                        cfg.writelines('disk0-part=SWAP 0 none\n')
                        cfg.writelines('commitDiskLabel\n')
                        break
                    else:
                        print 'choose (d)elete (c)reate (n)ext'
                        sleep(1)
                break
    # 3rd option advanced partitioning.
            elif INSTALL == '3':
                while True:
                    call('clear', shell=True)
                    print bootMenu
                    BOOT = raw_input('\n\nChose an option(1, 2): ')
                    if BOOT == '1':
                        BMANAGER = 'bootManager=bsd\n'
                        break
                    elif BOOT == '2':
                        BMANAGER = 'bootManager=none\n'
                        break
                while True:
                    call('clear', shell=True)
                    print ' Slice        Size     System'
                    print '---------------------------------'
                    #print '---------------------------------'
                    DLIST = '%s %s' % (disk_part, DISK)
                    p = Popen(DLIST, shell=True, stdout=PIPE, close_fds=True)
                    for line in p.stdout:
                        #print '---------------------------------'
                        print ' %s' % line.rstrip()
                        print '---------------------------------'
                    DPART = raw_input("(d)elete (c)reate (n)ext: ")
                    if DPART == "d":
                        DELPART = raw_input('Select the slice to delete(s1, s2, s3 or s4): ')
                        call('gpart delete -i %s %s' % (DELPART[-1], DISK), shell=True)
                        #call('%s delete-part %s%s' % (PC_SYS, DISK, DELPART), shell=True)
                        print "delete " + DISK + DELPART
                    elif DPART == "c":
                        CPART = int(raw_input('Enter size of partition to create: '))
                        call('%s create-part %s %s' % (PC_SYS, DISK, CPART))
                    elif DPART == "n":
                        while True:
                            SLICE = raw_input("Select the slice you wish to install GhostBSD to (s1' s2' s3 or s4): ")
                            if SLICE == 's1' or SLICE == 's2' or SLICE == 's3' or SLICE == 's4':
                                cfg.writelines('partition=%s' % SLICE)
                                break
                        cfg.writelines(BMANAGER)
                        cfg.writelines('commitDiskPart\n')
                        PART = int(raw_input("Enter the partition size of %s%s: " % (DISK, SLICE)))
                        break
                while True:
                    call('clear', shell=True)
                    print ' Partition label'
                    print ' fs size label'
                    print '------------------------'
                    if os.path.exists('%s/label' % PATH):
                        r = open('%s/label' % PATH, 'r')
                        line = r.read()
                        print ' %s' % line
                        print '\n'
                        print '--------------------------'
                        ARN = raw_input("\n(a)dd (r)eset (n)ext: ")
                    else:
                        print '\n\n\n\n\n-------------------------'
                        ARN = raw_input("(a)dd (r)eset (n)ext: ")
                    if ARN == 'a':
                        call('clear', shell=True)
                        print 'File System'
                        print '1: UFS'
                        print '2: UFS+S'
                        print '3: UFS+J'
                        print '4: ZFS'
                        print '5: SWAP'
                        FS = raw_input("Choose an File System(1, 2, 3, 4 or 5): ")
                        if FS == '1':
                            FSYS = 'UFS'
                        elif FS == '2':
                            FSYS = 'UFS+S'
                        elif FS == '3':
                            FSYS = 'UFS+J'
                        elif FS == '4':
                            FSYS = 'ZFS'
                        elif FS == '5':
                            FSYS = 'SWAP'
                        call('clear', shell=True)
                        print 'Partition Label Size'
                        print '\n'
                        if os.path.exists('%s/left' % PATH):
                            r = open('%s/left' % PATH, 'r')
                            left = r.read()
                            print 'Size: %sMB left' % left
                        else:
                            print 'Size: %sMB left' % PART
                            print '\n'
                        SIZE = int(raw_input("Enter the size: "))
                        LEFT = PART - SIZE
                        lf = open('%s/left' % PATH, 'w')
                        lf.writelines('%s' % LEFT)
                        lf.close()
                        call('clear', shell=True)
                        print 'Mount Point List'
                        print '/   /home /root'
                        print '/tmp   /usr   /var'
                        print 'none for swap.'
                        MP = raw_input('Enter a mount point: ')
                        f = open('%s/label' % PATH, 'a')
                        f.writelines('%s %s %s \n' % (FSYS, SIZE, MP))
                        f.close()
                    elif ARN == 'r':
                        if os.path.exists('%s/label' % PATH):
                            os.remove('%s/label' % PATH)
                        if os.path.exists('%s/left' % PATH):
                            os.remove('%s/left' % PATH)
                    elif ARN == 'n':
                        r = open('%s/label' % PATH, 'r')
                        i = r.readlines()
                        linecounter = 0
                        for line in i:
                            #print line
                            cfg.writelines('disk0-part=%s\n' % i[linecounter].rstrip())
                            linecounter += 1
                        cfg.writelines('commitDiskLabel\n')
                        break

                break
    # Hostname and network setting.

        HOSTNAME = raw_input('Type in your hostname: ')
        cfg.writelines('hostname=%s\n' % HOSTNAME)
        cfg.writelines('netDev=AUTO-DHCP\n')
        cfg.writelines('netSaveDev=AUTO-DHCP\n')

    # Root Password.
        call('clear', shell=True)
        print ' Root Password'
        print '----------------'
        while True:
            RPASS = getpass.getpass("\n Password: ")
            RRPASS = getpass.getpass("\n Confirm Password: ")
            if RPASS == RRPASS:
                cfg.writelines('rootPass=%s\n' % RPASS)
                break
            else:
                print "Password and password confirmation don't match. Try again!"
                sleep(1)

    # User setting.
        call('clear', shell=True)
        USER = raw_input(" Username: ")
        cfg.writelines('userName=%s\n' % USER)
        NAME = raw_input(" Real Name: ")
        cfg.writelines('userComment=%s\n' % NAME)
        while True:
            UPASS = getpass.getpass(" Password: ")
            RUPASS = getpass.getpass(" Confirm Password: ")
            if UPASS == RUPASS:
                cfg.writelines('userPass=%s\n' % UPASS)
                break
            else:
                print "Password and password confirmation don't match. Try again!"
                sleep(1)

        SHELL = raw_input("Shell(sh csh, tcsh, bash, rbash)- if you don't know just press Enter: ")
        if SHELL == 'sh':
            cfg.writelines('userShell=/bin/sh\n')
        elif SHELL == 'csh':
            cfg.writelines('userShell=/bin/csh\n')
        elif SHELL == 'tcsh':
            cfg.writelines('userShell=/bin/tcsh\n')
        elif SHELL == 'bash':
            cfg.writelines('userShell=/usr/local/bin/bash\n')
        elif SHELL == 'rbash':
            cfg.writelines('userShell=/usr/local/bin/rbash\n')
        else:
            cfg.writelines('userShell=/usr/local/bin/bash\n')
        cfg.writelines('userHome=/home/%s\n' % USER)
        cfg.writelines('userGroups=wheel,operator\n')
        cfg.writelines('commitUser\n')
        cfg.close()

    # Starting the installation.
        call('clear', shell=True)
        GINSTALL = raw_input("Ready To install GhostBSD now?(yes or no): ")
        if GINSTALL == "yes":
            print "install"
            #call("sudo umount -f /media", shell=True)
            call("%s -c %s" % (PC_SYS, CFG), shell=True)
        elif GINSTALL == "no":
            quit()
        call('clear', shell=True)
        print FIN
        RESTART = raw_input('Restart(yes or no): ')
        if RESTART == 'yes' or RESTART == 'YES' or RESTART == 'y' or RESTART == 'Y':
            call('sudo reboot', shell=True)
        if RESTART == 'no' or RESTART == 'NO' or RESTART == 'n' or RESTART == 'N':
            quit()

Ginstall()
