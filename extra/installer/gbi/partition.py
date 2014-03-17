#!/usr/local/bin/python
#
# Copyright (c) 2009-2012, GhostBSD. All rights reserved.
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
# partition.py v 1.3 Friday, January 17 2014 Eric Turgeon
#
# auto_partition.py create and delete partition slice for GhostBSD installer

import gtk
import os
import shutil
from defutil import partition_bbox, close_application
from partition_handler import partition_repos, disk_query, Delete_partition
from partition_handler import partition_query, label_query
from partition_handler import autoDiskPartition, autoFreeSpace
from partition_handler import createLabel, scheme_query, how_partition
from partition_handler import diskSchemeChanger, createSlice, createPartition

# Folder use pr the installer.
tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
query = "sh /usr/local/etc/gbi/backend-query/"
if not os.path.exists(tmp):
    os.makedirs(tmp)

add_part = 'gpart add'
disk_part = '%sdisk-part.sh' % query
disk_label = '%sdisk-label.sh' % query
detect_sheme = '%sdetect-sheme.sh' % query

part = '%sdisk-part.sh' % query
memory = 'sysctl hw.physmem'
disk_list = '%sdisk-list.sh' % query
disk_info = '%sdisk-info.sh' % query
disk_label = '%sdisk-label.sh' % query
disk_schem = '%sscheme' % tmp
disk_file = '%sdisk' % tmp
psize = '%spart_size' % tmp
logo = "/usr/local/etc/gbi/logo.png"
Part_label = '%spartlabel' % tmp
part_schem = '%sscheme' % tmp
partitiondb = "%spartitiondb/" % tmp


class Partitions():

    def on_fs(self, widget):
        self.fs = widget.get_active_text()

    def on_label(self, widget):
        self.label = widget.get_active_text()

    def on_add_label(self, widget, entry, inumb, path, data):
        if self.fs == '' or self.label == '':
            pass
        else:
            fs = self.fs
            lb = self.label
            cnumb = entry.get_value_as_int()
            lnumb = inumb - cnumb
            createLabel(path, lnumb, cnumb, lb, fs)
        self.window.hide()
        self.update()

    def on_add_partition(self, widget, entry, inumb, path, data):
        if self.fs == '' or self.label == '':
            pass
        else:
            fs = self.fs
            lb = self.label
            cnumb = entry.get_value_as_int()
            lnumb = inumb - cnumb
            createPartition(path, lnumb, inumb, cnumb, lb, fs, data)
        self.window.hide()
        self.update()

    def cancel(self, widget):
        self.window.hide()

    def labelEditor(self, path, pslice, size, data1, data2):
        numb = int(size)
        self.window = gtk.Window()
        self.window.set_title("Add Partition")
        self.window.set_border_width(0)
        self.window.set_position(gtk.WIN_POS_CENTER)
        self.window.set_size_request(480, 200)
        self.window.set_icon_from_file(logo)
        box1 = gtk.VBox(False, 0)
        self.window.add(box1)
        box1.show()
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        box1.pack_start(box2, True, True, 0)
        box2.show()

        # create label
        #label0 = gtk.Label("Create Partition Label")
        table = gtk.Table(1, 2, True)
        label1 = gtk.Label("Type:")
        label2 = gtk.Label("Size(MB):")
        label3 = gtk.Label("Mount point:")
        self.fs = 'UFS+SUJ'
        self.fstype = gtk.combo_box_new_text()
        self.fstype.append_text('UFS')
        self.fstype.append_text('UFS+S')
        self.fstype.append_text('UFS+J')
        self.fstype.append_text('UFS+SUJ')
        self.fstype.append_text('SWAP')
        if data1 == 1:
            self.fstype.append_text('BOOT')
        self.fstype.set_active(3)
        self.fstype.connect("changed", self.on_fs)
        adj = gtk.Adjustment(numb, 0, numb, 1, 100, 0)
        self.entry = gtk.SpinButton(adj, 10, 0)
        if data2 == 0:
            self.entry.set_editable(False)
        else:
            self.entry.set_editable(True)
        self.mountpoint = gtk.combo_box_entry_new_text()
        #self.mountpoint.append_text('select labels')
        self.label = "none"
        self.mountpoint.append_text('none')
        self.mountpoint.append_text('/')
        self.mountpoint.append_text('/boot')
        self.mountpoint.append_text('/etc')
        self.mountpoint.append_text('/home')
        self.mountpoint.append_text('/root')
        self.mountpoint.append_text('/tmp')
        self.mountpoint.append_text('/usr')
        self.mountpoint.append_text('/var')
        self.mountpoint.set_active(0)
        self.mountpoint.connect("changed", self.on_label)
        #table.attach(label0, 0, 2, 0, 1)
        table.attach(label1, 0, 1, 1, 2)
        table.attach(self.fstype, 1, 2, 1, 2)
        table.attach(label2, 0, 1, 2, 3)
        table.attach(self.entry, 1, 2, 2, 3)
        table.attach(label3, 0, 1, 3, 4)
        table.attach(self.mountpoint, 1, 2, 3, 4)
        box2.pack_start(table, False, False, 0)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, True, 0)
        box2.show()
        # Add button
        bbox = gtk.HButtonBox()
        bbox.set_border_width(5)
        bbox.set_layout(gtk.BUTTONBOX_END)
        bbox.set_spacing(10)
        button = gtk.Button(stock=gtk.STOCK_CANCEL)
        button.connect("clicked", self.cancel)
        bbox.add(button)
        button = gtk.Button(stock=gtk.STOCK_ADD)
        if data2 == 1:
            if data1 == 0:
                button.connect("clicked", self.on_add_label, self.entry, numb, path, True)
            elif  data1 == 1:
                button.connect("clicked", self.on_add_partition, self.entry, numb, path, True)
        else:
            if data1 == 0:
                button.connect("clicked", self.on_add_label, self.entry, numb, path, False)
            elif  data1 == 1:
                button.connect("clicked", self.on_add_partition, self.entry, numb, path, False)
        bbox.add(button)
        box2.pack_start(bbox, True, True, 5)
        self.window.show_all()

    def sheme_selection(self, combobox):
        model = combobox.get_model()
        index = combobox.get_active()
        data = model[index][0]
        value = data.partition(':')[0]
        self.sheme = value

    def add_gpt_mbr(self, widget, data):
        diskSchemeChanger(self.sheme, self.path)
        #self.update()
        self.window.hide()
        if data is None:
            autoDiskPartition(self.slice, self.size, self.scheme)
            self.update()
        elif scheme_query(self.path) == "MBR" and self.path[1] < 4:
            self.sliceEditor()
        elif scheme_query(self.path) == "GPT":
            self.labelEditor(self.path, self.slice, self.size, 1, 1)

    def schemeEditor(self, data):
        self.window = gtk.Window()
        self.window.set_title("Partition Scheme")
        self.window.set_border_width(0)
        self.window.set_position(gtk.WIN_POS_CENTER)
        self.window.set_size_request(400, 150)
        self.window.set_icon_from_file("/usr/local/etc/gbi/logo.png")
        box1 = gtk.VBox(False, 0)
        self.window.add(box1)
        box1.show()
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        box1.pack_start(box2, True, True, 0)
        box2.show()
        # Creating MBR or GPT drive
        label = gtk.Label('<b>Select a partition sheme for this drive:</b>')
        label.set_use_markup(True)
        # predetermine GPT sheme.
        self.sheme = "GPT"
        # Adding a combo box to selecting MBR or GPT sheme.
        shemebox = gtk.combo_box_new_text()
        shemebox.append_text("GPT: GUID Partition Table")
        shemebox.append_text("MBR: DOS Partitions")
        shemebox.connect('changed', self.sheme_selection)
        shemebox.set_active(0)
        table = gtk.Table(1, 2, True)
        table.attach(label, 0, 2, 0, 1)
        table.attach(shemebox, 0, 2, 1, 2)
        box2.pack_start(table, False, False, 0)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, True, 0)
        box2.show()
        # Add create_scheme button
        bbox = gtk.HButtonBox()
        bbox.set_border_width(5)
        bbox.set_layout(gtk.BUTTONBOX_END)
        bbox.set_spacing(10)
        button = gtk.Button(stock=gtk.STOCK_ADD)
        button.connect("clicked", self.add_gpt_mbr, data)
        bbox.add(button)
        box2.pack_start(bbox, True, True, 5)
        self.window.show_all()

    def get_value(self, widget, entry):
        psize = int(entry.get_value_as_int())
        rs = int(self.size) - psize
        createSlice(psize, rs, self.path)
        self.update()
        self.window.hide()

    def sliceEditor(self):
        numb = int(self.size)
        self.window = gtk.Window()
        self.window.set_title("Add Partition")
        self.window.set_border_width(0)
        self.window.set_position(gtk.WIN_POS_CENTER)
        self.window.set_size_request(400, 150)
        self.window.set_icon_from_file("/usr/local/etc/gbi/logo.png")
        box1 = gtk.VBox(False, 0)
        self.window.add(box1)
        box1.show()
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        box1.pack_start(box2, True, True, 0)
        box2.show()

        # create Partition slice
        #label = gtk.Label('<b>Create a New Partition Slice</b>')
        #label.set_use_markup(True)
        #label.set_alignment(0, .5)
        table = gtk.Table(1, 2, True)
        label1 = gtk.Label("Size(MB):")
        adj = gtk.Adjustment(numb, 0, numb, 1, 100, 0)
        self.entry = gtk.SpinButton(adj, 10, 0)
        self.entry.set_numeric(True)
        #table.attach(label, 0, 2, 0, 1)
        table.attach(label1, 0, 1, 1, 2)
        table.attach(self.entry, 1, 2, 1, 2)
        box2.pack_start(table, False, False, 0)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, True, 0)
        box2.show()
        # Add button
        bbox = gtk.HButtonBox()
        bbox.set_border_width(5)
        bbox.set_layout(gtk.BUTTONBOX_END)
        bbox.set_spacing(10)
        button = gtk.Button(stock=gtk.STOCK_CANCEL)
        button.connect("clicked", self.cancel)
        bbox.add(button)
        button = gtk.Button(stock=gtk.STOCK_ADD)
        button.connect("clicked", self.get_value, self.entry)
        bbox.add(button)
        box2.pack_start(bbox, True, True, 5)
        self.window.show_all()

    def update(self):
        self.Tree_Store()
        self.treeview.expand_all()
        self.treeview.set_cursor(self.path)

    def delete_partition(self, widget):
        part = self.slice
        Delete_partition(part, self.path)
        self.update()

    def delete_create_button(self, horizontal, spacing, layout):
        bbox = gtk.HButtonBox()
        bbox.set_border_width(5)
        bbox.set_layout(layout)
        bbox.set_spacing(spacing)
        button = gtk.Button("Create")
        button.connect("clicked", self.create_partition)
        bbox.add(button)
        button = gtk.Button("Delete")
        button.connect("clicked", self.delete_partition)
        bbox.add(button)
        button = gtk.Button("Modify")
        button.connect("clicked", self.modify_partition)
        bbox.add(button)
        button = gtk.Button("Revert")
        button.connect("clicked", self.revertChange)
        bbox.add(button)
        button = gtk.Button("Auto")
        button.connect("clicked", self.autoPartition)
        bbox.add(button)
        return bbox

    def modify_partition(self, widget):
        if len(self.path) == 3:
            if self.slice != 'freespace':
                self.labelEditor(self.path, self.slice, self.size, 0, 0)
        elif len(self.path) == 2 and self.slice != 'freespace':
            if scheme_query(self.path) == "GPT":
                self.labelEditor(self.path, self.slice, self.size, 1, 0)

    def autoPartition(self, widget):
        if len(self.path) == 3:
            pass
        elif len(self.path) == 1 and self.scheme is None:
            self.schemeEditor(None)
            self.Tree_Store()
            self.treeview.expand_all()
            self.treeview.set_cursor(self.path)
        elif len(self.path) == 1:
            autoDiskPartition(self.slice, self.size, self.scheme)
            self.Tree_Store()
            self.treeview.expand_all()
            self.treeview.set_cursor(self.path)
        elif self.slice == 'freespace':
            autoFreeSpace(self.path, self.size)
            self.Tree_Store()
            self.treeview.expand_all()
            self.treeview.set_cursor(self.path)
        elif len(self.path) == 2:
            pass
        else:
            print("not work")

    def revertChange(self, widget):
        if os.path.exists(partitiondb):
            shutil.rmtree(partitiondb)
        if os.path.exists(tmp + 'create'):
            os.remove(tmp + 'create')
        if os.path.exists(tmp + 'delete'):
            os.remove(tmp + 'delete')
        if os.path.exists(tmp + 'destroy'):
            os.remove(tmp + 'destroy')
        if os.path.exists(Part_label):
            os.remove(Part_label)
        partition_repos()
        self.Tree_Store()
        self.treeview.expand_all()

    def create_partition(self, widget):
        if len(self.path) == 3:
            if self.slice == 'freespace':
                self.labelEditor(self.path, self.slice, self.size, 0, 1)
        elif len(self.path) == 2 and self.slice == 'freespace':
            if how_partition(self.path) == 1:
                self.schemeEditor(True)
            elif scheme_query(self.path) == "MBR" and self.path[1] < 4:
                self.sliceEditor()
            elif scheme_query(self.path) == "GPT":
                self.labelEditor(self.path, self.slice, self.size, 1, 1)
        else:
            self.schemeEditor(True)

    def partition_selection(self, tree_selection):
        (model, pathlist) = tree_selection.get_selected_rows()
        for path in pathlist:
            tree_iter = model.get_iter(path)
            self.slice = model.get_value(tree_iter, 0)
            self.size = model.get_value(tree_iter, 1)
            #value2 = model.get_value(tree_iter, 2)
            self.scheme = model.get_value(tree_iter, 3)
            self.path = path

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
        Title = gtk.Label("<b><span size='xx-large'>Partition Editor</span></b> ")
        Title.set_use_markup(True)
        box2.pack_start(Title, False, False, 0)
        # Choosing disk to Select Create or delete partition.
        label = gtk.Label("<b>Select a drive:</b>")
        label.set_use_markup(True)
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        self.store = gtk.TreeStore(str, str, str, str, 'gboolean')
        self.Tree_Store()
        self.treeview = gtk.TreeView(self.store)
        self.treeview.set_model(self.store)
        self.treeview.set_rules_hint(True)
        cell = gtk.CellRendererText()
        column = gtk.TreeViewColumn(None, cell, text=0)
        column_header = gtk.Label('Partition')
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
        column_header3 = gtk.Label('Mount Point')
        column_header3.set_use_markup(True)
        column_header3.show()
        column3.set_widget(column_header3)
        cell4 = gtk.CellRendererText()
        column4 = gtk.TreeViewColumn(None, cell4, text=0)
        column_header4 = gtk.Label('System/Type')
        column_header4.set_use_markup(True)
        column_header4.show()
        column4.set_widget(column_header4)
        column.set_attributes(cell, text=0)
        column2.set_attributes(cell2, text=1)
        column3.set_attributes(cell3, text=2)
        column4.set_attributes(cell4, text=3)
        self.treeview.append_column(column)
        self.treeview.append_column(column2)
        self.treeview.append_column(column3)
        self.treeview.append_column(column4)
        self.treeview.set_reorderable(True)
        self.treeview.expand_all()
        tree_selection = self.treeview.get_selection()
        tree_selection.set_mode(gtk.SELECTION_SINGLE)
        tree_selection.connect("changed", self.partition_selection)
        sw.add(self.treeview)
        sw.show()
        box2.pack_start(sw)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, True, 0)
        box2.show()
        box2.pack_start(self.delete_create_button(True,
            10, gtk.BUTTONBOX_START),
            True, True, 5)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, True, 0)
        box2.show()
        box2.pack_start(partition_bbox(True,
        10, gtk.BUTTONBOX_END),
        True, True, 5)
        window.show_all()

    def Tree_Store(self):
        self.store.clear()
        for disk in disk_query():
            shem = disk[-1]
            piter = self.store.append(None, [disk[0], disk[1], disk[2], disk[3], True])
            if shem == "GPT":
                for pi in partition_query(disk[0]):
                    self.store.append(piter, [pi[0], pi[1], pi[2], pi[3], True])
            elif shem == "MBR":
                for pi in partition_query(disk[0]):
                    piter1 = self.store.append(piter, [pi[0], pi[1], pi[2], pi[3], True])
                    if pi[0] == 'freespace':
                        pass
                    else:
                        for li in label_query(pi[0]):
                            self.store.append(piter1, [li[0], li[1], li[2], li[3], True])
        return self.store

Partitions()
gtk.main()