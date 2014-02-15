#!/usr/bin/env python
# -*- coding: iso-8859-1 -*-
#
#####################################################################
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
#####################################################################
#
# $Id: gbi_keyboard.py v 0.3 Wednesday, May 30 2012 21:49 Eric Turgeon $


import gtk
import os.path
import os
from subprocess import call
from defutil import Keyboard_bbox, close_application

# Folder use for the installer.
tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
query = "sh /usr/local/etc/gbi/backend-query/"
if not os.path.exists(tmp):
    os.makedirs(tmp)

logo = "/usr/local/etc/gbi/logo.png"
xkeyboard_variant = "/usr/local/etc/gbi/keyboard/variant"
xkeyboard_layout = "/usr/local/etc/gbi/keyboard/layout"
layout = '%slayout' % tmp
variant = '%svariant' % tmp


# This class is for placeholder for entry.

class PlaceholderEntry(gtk.Entry):

    placeholder = 'Type here to test your keyboard'
    _default = True

    def __init__(self, *args, **kwds):
        gtk.Entry.__init__(self, *args, **kwds)
        self.set_text(self.placeholder)
        self.modify_text(gtk.STATE_NORMAL, gtk.gdk.color_parse("#4d4d4d"))
        self._default = True
        self.connect('focus-in-event', self._focus_in_event)
        self.connect('focus-out-event', self._focus_out_event)

    def _focus_in_event(self, widget, event):
        if self._default:
            self.set_text('')
            self.modify_text(gtk.STATE_NORMAL, gtk.gdk.color_parse('black'))

    def _focus_out_event(self, widget, event):
        if gtk.Entry.get_text(self) == '':
            self.set_text(self.placeholder)
            self.modify_text(gtk.STATE_NORMAL, gtk.gdk.color_parse("#4d4d4d"))
            self._default = True
        else:
            self._default = False

    def get_text(self):
        if self._default:
            return ''
        return gtk.Entry.get_text(self)


class Language:
    def layout_columns(self, treeView):
        cell = gtk.CellRendererText()
        column = gtk.TreeViewColumn(None, cell, text=0)
        column_header = gtk.Label('<b>Keyboard Layout</b>')
        column_header.set_use_markup(True)
        column_header.show()
        column.set_widget(column_header)
        column.set_sort_column_id(0)
        treeView.append_column(column)

    def variant_columns(self, treeView):
        cell = gtk.CellRendererText()
        column = gtk.TreeViewColumn(None, cell, text=0)
        column_header = gtk.Label('<b>Keyboard Variant</b>')
        column_header.set_use_markup(True)
        column_header.show()
        column.set_widget(column_header)
        column.set_sort_column_id(0)
        treeView.append_column(column)

    def Selection_Layout(self, tree_selection):
        (model, pathlist) = tree_selection.get_selected_rows()
        self.variant_store.clear()
        for path in pathlist:
            tree_iter = model.get_iter(path)
            value = model.get_value(tree_iter, 0)
        self.layout_txt = value
        if os.path.exists("%s/%s" % (xkeyboard_variant, value.partition("-")[2].strip())):
            read = open("%s/%s" % (xkeyboard_variant, value.partition("-")[2].strip()), 'r')
            for line in read.readlines():
                self.variant_store.append(None, [line.rstrip()])
        f = open(layout, 'w')
        f.writelines(self.layout_txt)
        f.close()
        call("setxkbmap %s" % self.layout_txt.partition("-")[2], shell=True)

    def Selection_Variant(self, tree_selection):
        (model, pathlist) = tree_selection.get_selected_rows()
        for path in pathlist:
            tree_iter = model.get_iter(path)
            value = model.get_value(tree_iter, 0)
            #print value
        self.variant_txt = value
        f = open(variant, 'w')
        f.writelines(self.variant_txt)
        f.close()
        call("setxkbmap %s %s" % (self.layout_txt.partition("-")[2],
        self.variant_txt.partition(":")[2]), shell=True)

    def __init__(self):
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        window.connect("destroy", close_application)
        window.set_size_request(700, 500)
        window.set_resizable(False)
        window.set_title("GhostBSD Installer")
        window.set_border_width(0)
        window.set_position(gtk.WIN_POS_CENTER)
        window.set_icon_from_file(logo)
        box1 = gtk.VBox(False, 0)
        window.add(box1)
        box1.show()
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        box1.pack_start(box2, True, True, 0)
        box2.show()
        table = gtk.Table(1, 2, True)
        label = gtk.Label('<span size="xx-large"><b>Keyboard Setup</b></span>')
        label.set_use_markup(True)
        table.attach(label, 0, 2, 0, 1)

        box2.pack_start(table, False, False, 0)
        hbox = gtk.HBox(False, 10)
        hbox.set_border_width(5)
        box2.pack_start(hbox, True, True, 5)
        hbox.show()

        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        store = gtk.TreeStore(str)
        read = open(xkeyboard_layout, 'r')
        for line in read.readlines():
            store.append(None, [line.rstrip()])
        treeView = gtk.TreeView(store)
        treeView.set_model(store)
        treeView.set_rules_hint(True)
        self.layout_columns(treeView)
        tree_selection = treeView.get_selection()
        tree_selection.set_mode(gtk.SELECTION_SINGLE)
        tree_selection.connect("changed", self.Selection_Layout)
        sw.add(treeView)
        sw.show()
        hbox.pack_start(sw, True, True, 5)

        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        self.variant_store = gtk.TreeStore(str)
        treeView = gtk.TreeView(self.variant_store)
        treeView.set_model(self.variant_store)
        treeView.set_rules_hint(True)
        self.variant_columns(treeView)
        tree_selection = treeView.get_selection()
        tree_selection.set_mode(gtk.SELECTION_SINGLE)
        tree_selection.connect("changed", self.Selection_Variant)
        sw.add(treeView)
        sw.show()
        hbox.pack_start(sw, True, True, 5)

        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, False, 0)
        box2.show()
        box2.pack_start(PlaceholderEntry(), True, True, 10)

        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, False, 0)
        box2.show()
        box2.pack_start(Keyboard_bbox(True,
                        10, gtk.BUTTONBOX_END),
                        True, True, 5)
        window.show_all()

Language()
gtk.main()
