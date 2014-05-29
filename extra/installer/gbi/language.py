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
# $Id: language.py v 0.4 Fryday, march 29 2011 15:20 Eric Turgeon $

# language.py show the language for the installer.


import gtk
import os
import os.path
from defutil import close_application, language_bbox

# Folder use for the installer.
tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
query = "sh /usr/local/etc/gbi/backend-query/"
if not os.path.exists(tmp):
    os.makedirs(tmp)

sysinstall = "sh /usr/local/etc/gbi/pc-sysinstall"
logo = "/usr/local/etc/gbi/logo.png"
language = "%slanguage/avail-langs" % installer
langfile = '%slanguage' % tmp

# Text to be replace be multiple language file.
welltitle = "Welcome To GhostBSD!"
welltext = """Select the language you want to use with GhostBSD."""


class Language():

    # On selection it overwrite the delfaut language file.
    def Language_Selection(self, tree_selection):
        (model, pathlist) = tree_selection.get_selected_rows()
        for path in pathlist:
            tree_iter = model.get_iter(path)
            value = model.get_value(tree_iter, 0)
        self.language = value
        lang_file = open(langfile, 'w')
        lang_file.writelines(self.language)
        lang_file.close()

    def Language_Columns(self, treeView):
        cell = gtk.CellRendererText()
        column = gtk.TreeViewColumn(None, cell, text=0)
        column_header = gtk.Label('Language')
        column_header.set_use_markup(True)
        column_header.show()
        column.set_widget(column_header)
        column.set_sort_column_id(0)
        treeView.append_column(column)

    # Initial definition.
    def __init__(self):

        # Defalt Window configuration.
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        window.connect("destroy", close_application)
        window.set_size_request(700, 500)
        window.set_title("GhostBSD Installer")
        window.set_resizable(False)
        window.set_border_width(0)
        window.set_position(gtk.WIN_POS_CENTER)
        window.set_icon_from_file(logo)
        # Add a Default vertical box
        vbox1 = gtk.VBox(False, 0)
        window.add(vbox1)
        vbox1.show()
        # Add a second vertical box
        vbox2 = gtk.VBox(False, 10)
        vbox2.set_border_width(10)
        vbox1.pack_start(vbox2, True, True, 0)
        vbox2.show()
        # Add a defalt horisontal
        hbox = gtk.HBox(False, 10)
        hbox.set_border_width(5)
        vbox2.pack_start(hbox, True, True, 5)
        hbox.show()
        # Adding a Scrolling Window
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        # Set English as default.
        l_file = open(language, 'r')
        lang_output = l_file.readlines()
        line0 = lang_output[0].strip()
        self.language = line0
        lang_file = open(langfile, 'w')
        lang_file.writelines(self.language)
        lang_file.close()
        # Adding a treestore and store language in it.
        store = gtk.TreeStore(str)
        for line in lang_output:
            store.append(None, [line.rstrip()])
        treeView = gtk.TreeView(store)
        treeView.set_model(store)
        treeView.set_rules_hint(True)
        self.Language_Columns(treeView)
        tree_selection = treeView.get_selection()
        tree_selection.set_mode(gtk.SELECTION_SINGLE)
        tree_selection.connect("changed", self.Language_Selection)
        sw.add(treeView)
        sw.show()
        hbox.pack_start(sw, True, True, 5)
        # add text in a label.
        vhbox = gtk.VBox(False, 0)
        vhbox.set_border_width(10)
        hbox.pack_start(vhbox, True, True, 5)
        vhbox.show()
        self.wellcometitle = gtk.Label('<span size="xx-large">' + welltitle + '</span>')
        self.wellcometitle.set_use_markup(True)
        self.wellcometext = gtk.Label(welltext)
        self.wellcometext.set_use_markup(True)
        table = gtk.Table()
        wall = gtk.Label()
        #table.attach(wall, 0, 1, 0, 1)
        table.attach(self.wellcometitle, 0, 1, 1, 2)
        wall = gtk.Label()
        table.attach(wall, 0, 1, 2, 3)
        table.attach(self.wellcometext, 0, 1, 3, 4)
        vhbox.pack_start(table, False, False, 5)
        image = gtk.Image()
        image.set_from_file(logo)
        image.show()
        vhbox.pack_start(image, True, True, 5)
        # Redoing vbox For bottom button.
        vbox2 = gtk.HBox(False, 10)
        vbox2.set_border_width(5)
        vbox1.pack_start(vbox2, False, False, 0)
        vbox2.show()
        # Button from defutil.
        vbox2.pack_start(language_bbox(True,
            10, gtk.BUTTONBOX_END),
            True, True, 5)
        window.show_all()

Language()
gtk.main()
