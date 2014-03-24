#!/usr/local/bin/python

import os
#import sys
import re
from subprocess import Popen, PIPE, STDOUT, call
import pickle

tmp = "/home/ghostbsd/.gbi/"
if not os.path.exists(tmp):
    os.makedirs(tmp)
installer = "/usr/local/etc/gbi/"
partitiondb = "%spartitiondb/" % tmp
query = "sh /usr/local/etc/gbi/backend-query/"
query_disk = '%sdisk-list.sh' % query
detect_sheme = '%sdetect-sheme.sh' % query
diskdb = "%sdisk" % partitiondb
query_partition = '%sdisk-part.sh' % query
query_label = '%sdisk-label.sh' % query
disk_info = '%sdisk-info.sh' % query
nl = "\n"
memory = 'sysctl hw.physmem'
disk_file = '%sdisk' % tmp
dslice = '%sslice' % tmp
Part_label = '%spartlabel' % tmp
part_schem = '%sscheme' % tmp


def disk_query():
    df = open(diskdb, 'rb')
    dl = pickle.load(df)
    return dl


def how_partition(path):
    disk = disk_query()[path[0]][0]
    part = partition_query(disk)
    return len(part)


def partition_query(disk):
    plist = open(partitiondb + disk, 'rb')
    pl = pickle.load(plist)
    return pl


def label_query(pslice):
    llist = open(partitiondb + pslice, 'rb')
    ll = pickle.load(llist)
    return ll


def scheme_query(path):
    disk = disk_query()[path[0]]
    return disk[-1]


def find_scheme(disk):
        cmd = "%s %s" % (detect_sheme, disk)
        shm_out = Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        scheme = shm_out.stdout.readlines()[0].rstrip()
        return scheme


def int_size(size):
    size = int(size)
    return size


def rpartslice(part):
    item = part
    p = set("p")
    s = set("s")
    if p & set(item):
        drive = item.partition('p')[0]
    elif s & set(item):
        drive = item.partition('s')[0]
    return drive


def sliceNum(part):
    item = part
    p = set("p")
    s = set("s")
    if p & set(item):
        num = int(item.partition('p')[2])
    elif s & set(item):
        num = int(item.partition('s')[2])
    return num


def slicePartition(part):
    item = part
    p = set("p")
    s = set("s")
    if p & set(item):
        return 'p'
    elif s & set(item):
        return 's'


class diskSchemeChanger():

    def __init__(self, schm, path, disk, size):
        dlist = disk_query()
        dselected = dlist[path[0]]
        dselected[-1] = schm
        dlist[path[0]] = dselected
        disk = dselected[0]
        df = open(diskdb, 'wb')
        pickle.dump(dlist, df)
        df.close()
        dsl = []
        mdsl = []
        if os.path.exists(tmp + 'destroy'):
            df = open(tmp + 'destroy', 'rb')
            mdsl = pickle.load(df)
        dsl.extend(([disk, schm]))
        mdsl.append(dsl)
        cf = open(tmp + 'destroy', 'wb')
        pickle.dump(mdsl, cf)
        cf.close()
        if not os.path.exists(partitiondb + disk):
            plist = []
            mplist = []
            psf = open(partitiondb + disk, 'wb')
            plist.extend((['freespace', size, '', '']))
            mplist.append(plist)
            pickle.dump(mplist, psf)
            psf.close()


class partition_repos():

    def disk_list(self):
        disk_output = Popen(query_disk, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        dlist = []
        for disk in disk_output.stdout:
            dlist.append(disk.split())
        return dlist

    def disk_size(self, disk):
        cmd = "%s %s" % (disk_info, disk)
        ds = Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        diskSize = ds.stdout.readlines()[0].rstrip()
        return diskSize

    def find_Scheme(self, disk):
        cmd = "%s %s" % (detect_sheme, disk)
        shm_out = Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        scheme = shm_out.stdout.readlines()[0].rstrip()
        return scheme

    def mbr_partition_slice_list(self, disk):
        partition_outpput = Popen('%s %s' % (query_partition, disk), shell=True,
        stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
        plist = []
        mplist = []
        dpsf = open(partitiondb + disk, 'wb')
        for line in partition_outpput.stdout:
            info = line.split()
            plist.extend((info[0], info[1].partition('M')[0], '', info[2]))
            mplist.append(plist)
            #print(plist)
            plist = []
            self.mbr_partition_list(info[0])
        pickle.dump(mplist, dpsf)
        dpsf.close()

    def mbr_partition_list(self, pslice):
        slice_outpput = Popen('%s %s' % (query_label, pslice), shell=True,
        stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
        alph = ord('a')
        if pslice == 'freespace':
            pass
        else:
            llist = []
            mllist = []
            plf = open(partitiondb + pslice, 'wb')
            for line in slice_outpput.stdout:
                info = line.split()
                letter = chr(alph)
                alph = alph + 1
                if info[0] == 'freespace':
                    llist.extend(([info[0], info[1].partition('M')[0], '', '']))
                else:
                    llist.extend((
                    [pslice + letter, info[0].partition('M')[0], '', info[1]]))
                mllist.append(llist)
                #print(llist)
                llist = []
            pickle.dump(mllist, plf)
            plf.close()

    def gpt_partition_list(self, disk):
        partition_outpput = Popen('%s %s' % (query_partition, disk), shell=True,
        stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
        plist = []
        mplist = []
        psf = open(partitiondb + disk, 'wb')
        for line in partition_outpput.stdout:
            info = line.split()
            plist.extend((info[0], info[1].partition('M')[0], '', info[2]))
            mplist.append(plist)
            #print(plist)
            plist = []
        #print(mplist)
        pickle.dump(mplist, psf)
        psf.close()

    def __init__(self):
        if not os.path.exists(partitiondb):
            os.makedirs(partitiondb)
        df = open(diskdb, 'wb')
        dlist = []
        mdlist = []
        for disk in self.disk_list():
            if self.find_Scheme(disk[0]) == "GPT":
                dlist.extend(([disk[0], self.disk_size(disk[0]), '', 'GPT']))
                self.gpt_partition_list(disk[0])
                mdlist.append(dlist)
            elif self.find_Scheme(disk[0]) == "MBR":
                dlist.extend(([disk[0], self.disk_size(disk[0]), '', 'MBR']))
                self.mbr_partition_slice_list(disk[0])
                mdlist.append(dlist)
            else:
                dlist.extend(([disk[0], self.disk_size(disk[0]), '', None]))
                mdlist.append(dlist)
            dlist = []
        pickle.dump(mdlist, df)
        df.close()


class Delete_partition():

    def find_if_lable(seff, part):
        last = part[-1]
        if re.search('[a-z]', last):
            return True

    def delete_label(self, part, spart, path):
        llist = open(partitiondb + spart, 'r')
        ll = pickle.load(llist)
        last_num = len(ll) - 1
        lnum = path[2]
        if last_num == lnum:
            free = int_size(ll[last_num][1])
            if lnum != 0 and ll[lnum - 1][0] == 'freespace':
                free = free + int_size(ll[lnum - 1][1])
                ll[lnum] = ['freespace', free, '', '']
                ll.remove(ll[lnum - 1])
            else:
                ll[lnum] = ['freespace', free, '', '']
        elif lnum == 0:
            free = int_size(ll[lnum][1])
            if ll[lnum + 1][0] == 'freespace':
                free = free + int_size(ll[lnum + 1][1])
                ll.remove(ll[lnum + 1])
            ll[lnum] = ['freespace', free, '', '']
        else:
            free = int_size(ll[lnum][1])
            if ll[lnum + 1][0] == 'freespace':
                free = free + int_size(ll[lnum + 1][1])
                ll.remove(ll[lnum + 1])
            if lnum != 0 and ll[lnum - 1][0] == 'freespace':
                free = free + int_size(ll[lnum - 1][1])
                ll[lnum] = ['freespace', free, '', '']
                ll.remove(ll[lnum - 1])
            else:
                ll[lnum] = ['freespace', free, '', '']
        savepl = open(partitiondb + spart, 'w')
        pickle.dump(ll, savepl)
        savepl.close()

    def __init__(self, part, path):
        if part == "freespace":
            pass
        elif self.find_if_lable(part) is True:
            spart = part[:-1]
            self.delete_label(part, spart, path)
        else:
            drive = rpartslice(part)
            self.delete_slice(drive, part, path)

    def delete_slice(self, drive, part, path):
        slist = open(partitiondb + drive, 'r')
        sl = pickle.load(slist)
        last_num = len(sl) - 1
        snum = path[1]
        if last_num == snum:
            free = int_size(sl[last_num][1])
            dl = []
            mdl = []
            if os.path.exists(tmp + 'delete'):
                df = open(tmp + 'delete', 'rb')
                mdl = pickle.load(df)
            dl.extend(([part, free]))
            mdl.append(dl)
            cf = open(tmp + 'delete', 'wb')
            pickle.dump(mdl, cf)
            cf.close()
            if snum != 0 and sl[snum - 1][0] == 'freespace':
                free = free + int_size(sl[snum - 1][1])
                sl[snum] = ['freespace', free, '', '']
                sl.remove(sl[snum - 1])
            else:
                sl[snum] = ['freespace', free, '', '']
        elif snum == 0:
            free = int_size(sl[snum][1])
            dl = []
            mdl = []
            if os.path.exists(tmp + 'delete'):
                df = open(tmp + 'delete', 'rb')
                mdl = pickle.load(df)
            dl.extend(([part, free]))
            mdl.append(dl)
            cf = open(tmp + 'delete', 'wb')
            pickle.dump(mdl, cf)
            cf.close()
            if sl[snum + 1][0] == 'freespace':
                free = free + int_size(sl[snum + 1][1])
                sl.remove(sl[snum + 1])
            sl[snum] = ['freespace', free, '', '']
        else:
            free = int_size(sl[snum][1])
            dl = []
            mdl = []
            if os.path.exists(tmp + 'delete'):
                df = open(tmp + 'delete', 'rb')
                mdl = pickle.load(df)
            dl.extend(([part, free]))
            mdl.append(dl)
            cf = open(tmp + 'delete', 'wb')
            pickle.dump(mdl, cf)
            cf.close()
            if sl[snum + 1][0] == 'freespace':
                free = free + int_size(sl[snum + 1][1])
                sl.remove(sl[snum + 1])
            if snum != 0 and sl[snum - 1][0] == 'freespace':
                free = free + int_size(sl[snum - 1][1])
                sl[snum] = ['freespace', free, '', '']
                sl.remove(sl[snum - 1])
            else:
                sl[snum] = ['freespace', free, '', '']
        if os.path.exists(partitiondb + part):
            os.remove(partitiondb + part)
        saveps = open(partitiondb + drive, 'w')
        pickle.dump(sl, saveps)
        saveps.close()


class autoDiskPartition():

    def delete_mbr_partition(self, disk):
        plist = partition_query(disk)
        for part in plist:
            if part[0] == 'freespace':
                pass
            else:
                os.remove(partitiondb + part[0])

    def create_mbr_partiton(self, disk, size):
        file_disk = open(disk_file, 'w')
        file_disk.writelines('%s\n' % disk)
        file_disk.close()
        sfile = open(part_schem, 'w')
        sfile.writelines('partscheme=MBR')
        sfile.close()
        plist = []
        mplist = []
        dpsf = open(partitiondb + disk, 'wb')
        plist.extend((disk + "s1", size, '', 'freebsd'))
        mplist.append(plist)
        pickle.dump(mplist, dpsf)
        dpsf.close()
        number = int(size.partition('M')[0])
        slice_file = open(dslice, 'w')
        slice_file.writelines('all\n')
        slice_file.writelines('%s\n' % number)
        slice_file.close()
        ram = Popen(memory, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        mem = ram.stdout.read()
        swap = int(mem.partition(':')[2].strip()) / (1024 * 1024)
        rootNum = number - swap
        llist = []
        mllist = []
        plf = open(partitiondb + disk + 's1', 'wb')
        llist.extend(([disk + 's1a', number, '/', 'freebsd-ufs']))
        mllist.append(llist)
        llist = []
        llist.extend(([disk + 's1b', swap, 'none', 'freebsd-swap']))
        mllist.append(llist)
        pickle.dump(mllist, plf)
        plf.close()
        pfile = open(Part_label, 'w')
        pfile.writelines('UFS+SUJ %s /\n' % rootNum)
        pfile.writelines('SWAP 0 none\n')
        pfile.close()

    def __init__(self, disk, size, schm):
        if schm == 'GPT':
            self.create_gpt_partiton(disk, size)
        elif schm == 'MBR':
            if os.path.exists(partitiondb + disk):
                self.delete_mbr_partition(disk)
            self.create_mbr_partiton(disk, size)

    def create_gpt_partiton(self, disk, size):
        file_disk = open(disk_file, 'w')
        file_disk.writelines('%s\n' % disk)
        file_disk.close()
        sfile = open(part_schem, 'w')
        sfile.writelines('partscheme=GPT')
        sfile.close()
        number = int(size.partition('M')[0])
        slice_file = open(dslice, 'w')
        slice_file.writelines('all\n')
        slice_file.writelines('%s\n' % number)
        slice_file.close()
        ram = Popen(memory, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        mem = ram.stdout.read()
        swap = int(mem.partition(':')[2].strip()) / (1024 * 1024)
        rootNum = number - swap
        plist = []
        mplist = []
        plf = open(partitiondb + disk, 'wb')
        plist.extend(([disk + 'p1', number, '/', 'freebsd-ufs']))
        mplist.append(plist)
        plist = []
        plist.extend(([disk + 'p2', swap, 'none', 'freebsd-swap']))
        mplist.append(plist)
        pickle.dump(mplist, plf)
        plf.close()
        pfile = open(Part_label, 'w')
        pfile.writelines('UFS+SUJ %s /\n' % rootNum)
        pfile.writelines('SWAP 0 none\n')
        pfile.close()


class autoFreeSpace():

    def create_mbr_partiton(self, disk, size, sl, path):
        file_disk = open(disk_file, 'w')
        file_disk.writelines('%s\n' % disk)
        file_disk.close()
        sfile = open(part_schem, 'w')
        sfile.writelines('partscheme=MBR')
        sfile.close()
        plist = []
        mplist = partition_query(disk)
        dpsf = open(partitiondb + disk, 'wb')
        plist.extend((disk + "s%s" % sl, size, '', 'freebsd'))
        mplist[path] = plist
        pickle.dump(mplist, dpsf)
        dpsf.close()
        number = int(size)
        slice_file = open(dslice, 'w')
        slice_file.writelines('s%s\n' % sl)
        slice_file.writelines('%s\n' % number)
        slice_file.close()
        ram = Popen(memory, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        mem = ram.stdout.read()
        swap = int(mem.partition(':')[2].strip()) / (1024 * 1024)
        rootNum = number - swap
        llist = []
        mllist = []
        plf = open(partitiondb + disk + 's%s' % sl, 'wb')
        llist.extend(([disk + 's%sa' % sl, rootNum, '/', 'freebsd-ufs']))
        mllist.append(llist)
        llist = []
        llist.extend(([disk + 's%sb' % sl, swap, 'none', 'freebsd-swap']))
        mllist.append(llist)
        pickle.dump(mllist, plf)
        plf.close()
        pfile = open(Part_label, 'w')
        pfile.writelines('UFS+SUJ %s /\n' % rootNum)
        pfile.writelines('SWAP 0 none\n')
        pfile.close()
        pl = []
        mpl = []
        if os.path.exists(tmp + 'create'):
            pf = open(tmp + 'create', 'rb')
            mpl = pickle.load(pf)
        pl.extend(([disk + "s%s" % sl, size]))
        mpl.append(pl)
        cf = open(tmp + 'create', 'wb')
        pickle.dump(mpl, cf)
        cf.close()

    def __init__(self, path, size):
        disk = disk_query()[path[0]][0]
        schm = disk_query()[path[0]][3]
        sl = path[1] + 1
        lv = path[1]
        if schm == "GPT":
            self.create_gpt_partiton(disk, size, sl, lv)
        elif schm == "MBR":
            self.create_mbr_partiton(disk, size, sl, lv)

    def create_gpt_partiton(self, disk, size, sl, path):
        file_disk = open(disk_file, 'w')
        file_disk.writelines('%s\n' % disk)
        file_disk.close()
        sfile = open(part_schem, 'w')
        sfile.writelines('partscheme=GPT')
        sfile.close()
        number = int(size.partition('M')[0])
        slice_file = open(dslice, 'w')
        slice_file.writelines('p%s\n' % sl)
        slice_file.writelines('%s\n' % number)
        slice_file.close()
        ram = Popen(memory, shell=True, stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, close_fds=True)
        mem = ram.stdout.read()
        swap = int(mem.partition(':')[2].strip()) / (1024 * 1024)
        rootNum = number - swap
        bs = 1
        rootNum = rootNum - bs
        plist = []
        mplist = partition_query(disk)
        plf = open(partitiondb + disk, 'wb')
        plist.extend(([disk + 'p%s' % sl, bs, 'none', 'freebsd-boot']))
        mplist[path] = plist
        plist = []
        plist.extend((
        [disk + 'p%s' % int(sl + 1), rootNum, '/', 'freebsd-ufs']))
        mplist[path] = plist
        mplist.append(plist)
        plist.extend((
        [disk + 'p%s' % int(sl + 2), swap, 'none', 'freebsd-swap']))
        mplist.append(plist)
        pickle.dump(mplist, plf)
        plf.close()
        pfile = open(Part_label, 'w')
        pfile.writelines('UFS+SUJ %s /\n' % rootNum)
        pfile.writelines('SWAP 0 none\n')
        pfile.close()
        pl = []
        mpl = []
        if not os.path.exists(tmp + 'create'):
            pl.extend(([disk + "p%s" % sl, size]))
            mpl.append(pl)
            cf = open(tmp + 'create', 'wb')
            pickle.dump(mpl, cf)
            cf.close()


class createLabel():

    def __init__(self, path, lnumb, cnumb, lb, fs, data):
        disk = disk_query()[path[0]][0]
        #schm = disk_query()[path[0]][3]
        sl = path[1] + 1
        lv = path[2]
        #slice_file = open(dslice, 'w')
        #slice_file.writelines('s%s\n' % sl)
        #slice_file.writelines('%s\n' % number)
        #slice_file.close()
        alph = ord('a')
        alph += lv
        letter = chr(alph)
        llist = []
        mllist = label_query(disk + 's%s' % sl)
        plf = open(partitiondb + disk + 's%s' % sl, 'wb')
        if fs == 'UFS' or fs == 'UFS+S' or fs == 'UFS+J' or fs == 'UFS+SUJ':
            llist.extend((
            [disk + 's%s' % sl + letter, cnumb, lb, 'freebsd-ufs']))
        elif fs == 'SWAP':
            llist.extend((
            [disk + 's%s' % sl + letter, cnumb, lb, 'freebsd-swap']))
        #elif == 'ZFS':
        mllist[lv] = llist
        llist = []
        if lnumb > 0:
            llist.extend((['freespace', lnumb, '', '']))
            mllist.append(llist)
        pickle.dump(mllist, plf)
        plf.close()
        pfile = open(Part_label, 'a')
        pfile.writelines('%s %s %s\n' % (fs, cnumb, lb))
        pfile.close()


class createSlice():

    def __init__(self, size, rs, path):
        disk = disk_query()[path[0]][0]
        file_disk = open(disk_file, 'w')
        file_disk.writelines('%s\n' % disk)
        file_disk.close()
        if len(path) == 1:
            sl = 1
        else:
            sl = path[1] + 1
        sfile = open(part_schem, 'w')
        sfile.writelines('partscheme=MBR')
        sfile.close()
        slice_file = open(dslice, 'w')
        slice_file.writelines('s%s\n' % sl)
        #slice_file.writelines('%s\n' % number)
        slice_file.close()
        plist = partition_query(disk)
        pslice = '%ss%s' % (disk, path[1] + 1)
        plist[path[1]] = [pslice, size, '', 'freebsd']
        if rs > 0:
            plist.append(['freespace', rs, '', ''])
        psf = open(partitiondb + disk, 'wb')
        pickle.dump(plist, psf)
        psf.close()
        llist = []
        mllist = []
        llist.extend((['freespace', size, '', '']))
        mllist.append(llist)
        plf = open(partitiondb + pslice, 'wb')
        pickle.dump(mllist, plf)
        plf.close()
        slice_file = open(dslice, 'w')
        slice_file.writelines('s%s\n' % pslice)
        slice_file.close()
        pl = []
        mpl = []
        if os.path.exists(tmp + 'create'):
            pf = open(tmp + 'create', 'rb')
            mpl = pickle.load(pf)
        pl.extend(([pslice, size]))
        mpl.append(pl)
        cf = open(tmp + 'create', 'wb')
        pickle.dump(mpl, cf)
        cf.close()


class createPartition():

    def __init__(self, path, lnumb, inumb, cnumb, lb, fs, data):
        disk = disk_query()[path[0]][0]
        if not os.path.exists(disk_file):
            file_disk = open(disk_file, 'w')
            file_disk.writelines('%s\n' % disk)
            file_disk.close()
        if len(path) == 1:
            pl = 1
        else:
            pl = path[1] + 1
        lv = path[1]
        if not os.path.exists(part_schem):
            sfile = open(part_schem, 'w')
            sfile.writelines('partscheme=GPT')
            sfile.close()
        if not os.path.exists(dslice):
            slice_file = open(dslice, 'w')
            slice_file.writelines('p%s\n' % pl)
            #slice_file.writelines('%s\n' % number)
            slice_file.close()
        plist = []
        pslice = '%sp%s' % (disk, pl)
        mplist = partition_query(disk)
        pf = open(partitiondb + disk, 'wb')
        if fs == 'UFS' or fs == 'UFS+S' or fs == 'UFS+J' or fs == 'UFS+SUJ':
            plist.extend(([disk + 'p%s' % pl, cnumb, lb, 'freebsd-ufs']))
        elif fs == 'SWAP':
            plist.extend(([disk + 'p%s' % pl, cnumb, lb, 'freebsd-swap']))
        elif fs == 'BOOT':
            plist.extend(([disk + 'p%s' % pl, cnumb, lb, 'freebsd-boot']))
        mplist[lv] = plist
        plist = []
        if lnumb > 0:
            plist.extend((['freespace', lnumb, '', '']))
            mplist.append(plist)
        pickle.dump(mplist, pf)
        pf.close()
        pfile = open(Part_label, 'a')
        pfile.writelines('%s %s %s\n' % (fs, cnumb, lb))
        pfile.close()
        if data is True:
            plst = []
            mplst = []
            if not os.path.exists(tmp + 'create'):
                plst.extend(([pslice, cnumb]))
                mplst.append(plst)
                cf = open(tmp + 'create', 'wb')
                pickle.dump(mplst, cf)
                cf.close()


class rDeleteParttion():

    def __init__(self):
        if os.path.exists(tmp + 'delete'):
            df = open(tmp + 'delete', 'rb')
            dl = pickle.load(df)
            for line in dl:
                part = line[0]
                num = sliceNum(part)
                hd = rpartslice(part)
                print(('gpart delete -i %s %s' % (num, hd)))
                call('gpart delete -i %s %s' % (num, hd), shell=True)


class destroyParttion():
    def __init__(self):
        if os.path.exists(tmp + 'destroy'):
            dsf = open(tmp + 'destroy', 'rb')
            ds = pickle.load(dsf)
            for line in ds:
                drive = line[0]
                print(('gpart destroy -F %s' % drive))
                call('gpart destroy -F %s' % drive, shell=True)
                scheme = line[1]
                print(('gpart create -s %s %s' % (scheme.lower(), drive)))
                call('gpart create -s %s %s' % (scheme.lower(),
                 drive), shell=True)


class makingParttion():

    def __init__(self):
        if os.path.exists(tmp + 'create'):
            pf = open(tmp + 'create', 'rb')
            pl = pickle.load(pf)
            size = 0
            for line in pl:
                part = line[0]
                drive = rpartslice(part)
                sl = sliceNum(part)
                if slicePartition(part) == 'p':
                    cmd = 'gpart add -s 512 -t freebsd-boot -i %s %s' % (sl, drive)
                    print(cmd)
                    call(cmd, shell=True)
                elif slicePartition(part) == 's':
                    size = int(line[1])
                    block = int(size * 2048)
                    print(('gpart add -s %s -t freebsd %s' % (block, drive)))
                    cmd = 'gpart add -s %s -t freebsd %s' % (block, drive)
                    call(cmd, shell=True)
