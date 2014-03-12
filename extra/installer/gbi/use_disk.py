#!/usr/bin/env python
#
#
# Copyright (c) 2009-2013, GhostBSD. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistribution's of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistribution's in binary form must reproduce the above
#    copyright notice,this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#
# 3. Neither then name of GhostBSD Project nor the names of its
#    contributors maybe used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES(INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# use_disk.py v 1.3 Sunday, December 22 2013 Eric Turgeon
#
# use_disk.py setthing GhostBSD to install entirely in a disk.

import gtk
import os
import os.path
from subprocess import Popen, PIPE, STDOUT
from defutil import use_disk_bbox, close_application
from partition_handler import disk_query

# Folder use pr the installer.
tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
query = "sh /usr/local/etc/gbi/backend-query/"
if not os.path.exists(tmp):
    os.makedirs(tmp)

logo = "/usr/local/etc/gbi/logo.png"
memory = 'sysctl hw.physmem'
auto = '%sauto' % tmp
disk_info = '%sdisk-info.sh' % query
disk_file = '%sdisk' % tmp
dslice = '%sslice' % tmp
Part_label = '%spartlabel' % tmp
part_schem = '%sscheme' % tmp
disk_list = '%sdisk-list.sh' % query


class Entire():
    def Selection_Variant(self, tree_selection):
        (model, pathlist) = tree_selection.get_selected_rows()
        for path in pathlist:
            tree_iter = model.get_iter(path)
            value = model.get_value(tree_iter, 0)
            value2 = model.get_value(tree_iter, 1)
            value3 = model.get_value(tree_iter, 2)
        self.disk = value
        self.size = value2
        if value3 is None:
            self.schm = 'GPT'
        else:
            self.schm = value3
        sfile = open(part_schem, 'w')
        sfile.writelines('partscheme=%s' % self.schm)
        sfile.close()
        file_disk = open(disk_file, 'w')
        file_disk.writelines('%s\n' % self.disk)
        file_disk.close()
        NUMBER = int(self.size)
        slice_file = open(dslice, 'w')
        slice_file.writelines('all\n')
        #slice_file.writelines('%s\n' % NUMBER)
        slice_file.close()
        ram = Popen(memory, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT,
        close_fds=True)
        mem = ram.stdout.read()
        SWAP = int(mem.partition(':')[2].strip()) / (1024 * 1024)
        NUM1 = NUMBER - SWAP
        pfile = open(Part_label, 'w')
        pfile.writelines('UFS+SUJ %s /\n' % NUM1)
        pfile.writelines('SWAP 0 none\n')
        pfile.close()

    def __init__(self):
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        window.connect("destroy", close_application)
        window.set_size_request(700, 500)
        window.set_resizable(False)
        window.set_title("GhostBSD Installer")
        window.set_border_width(0)
        window.set_position(gtk.WIN_POS_CENTER)
        window.set_icon_from_file("/usr/local/etc/gbi/logo.png")
        box1 = gtk.VBox(False, 0)
        window.add(box1)
        box1.show()
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        box1.pack_start(box2, True, True, 0)
        box2.show()
        # Title
        Title = gtk.Label("<b><span size='xx-large'>Install GhostBSD entirely on disk</span></b> ")
        Title.set_use_markup(True)
        box2.pack_start(Title, False, False, 0)
        # chose Disk
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        store = gtk.TreeStore(str, str, str, 'gboolean')
        for disk in disk_query():
            store.append(None, [disk[0], disk[1], disk[3], True])
        treeView = gtk.TreeView(store)
        treeView.set_model(store)
        treeView.set_rules_hint(True)
        cell = gtk.CellRendererText()
        column = gtk.TreeViewColumn(None, cell, text=0)
        column_header = gtk.Label('Disk')
        column_header.set_use_markup(True)
        column_header.show()
        column.set_widget(column_header)
        column.set_sort_column_id(0)
        cell2 = gtk.CellRendererText()
        column2 = gtk.TreeViewColumn(None, cell2, text=0)
        column_header2 = gtk.Label('Size(MB)')
        column_header2.set_use_markup(True)
        column_header2.show()
        column2.set_widget(column_header2)
        cell3 = gtk.CellRendererText()
        column3 = gtk.TreeViewColumn(None, cell3, text=0)
        column_header3 = gtk.Label('Scheme')
        column_header3.set_use_markup(True)
        column_header3.show()
        column3.set_widget(column_header3)
        column.set_attributes(cell, text=0)
        column2.set_attributes(cell2, text=1)
        column3.set_attributes(cell3, text=2)
        treeView.append_column(column)
        treeView.append_column(column2)
        treeView.append_column(column3)
        tree_selection = treeView.get_selection()
        tree_selection.set_mode(gtk.SELECTION_SINGLE)
        tree_selection.connect("changed", self.Selection_Variant)
        sw.add(treeView)
        sw.show()
        box2.pack_start(sw, True, True, 10)
        sfile = open(part_schem, 'w')
        sfile.writelines('partscheme=GPT')
        sfile.close()
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, False, 0)
        box2.show()
        # Add button
        box2.pack_start(use_disk_bbox(True,
                        10, gtk.BUTTONBOX_END),
                        True, True, 5)
        window.show_all()

Entire()
gtk.main()
