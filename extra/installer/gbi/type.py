#!/usr/bin/env python
#
# Copyright (c) 2013 GhostBSD
#
# See COPYING for licence terms.
#
# type.py v 0.3 Thursday, Mar 28 2013 19:31:53 Eric Turgeon
#
# type.py create and delete partition slice for GhostBSD system.

import gtk
import os
import os.path
from defutil import type_bbox, close_application
from partition_handler import partition_repos

# Folder use pr the installer.
tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
query = "sh /usr/local/etc/gbi/backend-query/"
if not os.path.exists(tmp):
    os.makedirs(tmp)

sysinstall = "sh /usr/local/etc/gbi/pc-sysinstall"
logo = "/usr/local/etc/gbi/logo.png"
disk_file = '%sdisk' % tmp
boot_file = '%sboot' % tmp
signal = '%ssignal' % tmp
disk_list = '%sdisk-list.sh' % query
disk_info = '%sdisk-info.sh' % query
part_query = '%sdisk-part.sh' % query


class Types():

    def partition(self, radiobutton, val):
        self.ne = val
        pass_file = open(signal, 'w')
        pass_file.writelines(self.ne)
        pass_file.close

    def on_check(self, widget):
        if widget.get_active():
            self.boot = "bsd"
        else:
            self.boot = 'none'
        boot = open(boot_file, 'w')
        boot.writelines(self.boot)
        boot.close()

    def __init__(self):
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        window.connect("destroy", close_application)
        window.set_size_request(500, 300)
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

        #auto partition or Customize Disk Partition.
        bbox = gtk.VBox()
        label = gtk.Label()
        box2.pack_start(label, False, False, 0)
        label = gtk.Label('<b><span size="xx-large">Installation Type</span></b>')
        label.set_use_markup(True)
        box2.pack_start(label, False, False, 10)
        # create a Hbox to center the radio button.
        hbox = gtk.HBox()
        box2.pack_start(hbox, True, True, 10)

        radio = gtk.RadioButton(None, "Use Entire Disk")
        bbox.pack_start(radio, False, True, 10)
        radio.connect("toggled", self.partition, "user")
        self.ne = 'user'
        pass_file = open(signal, 'w')
        pass_file.writelines(self.ne)
        pass_file.close
        radio.show()
        #box2.pack_start(radio, True, True, 10)
        radio = gtk.RadioButton(radio, "Partition Editor")
        bbox.pack_start(radio, False, True, 10)
        radio.connect("toggled", self.partition, "custom")
        radio.show()
        #box2.pack_start(radio, True, True, 10)

        hbox.pack_start(bbox, True, True, 100)

        # Boot option.
        label = gtk.Label('<b><span size="large">Boot Option</span></b>')
        label.set_use_markup(True)
        #table = gtk.Table(1, 2, True)
        check = gtk.CheckButton("Install BSD Boot Loader")
        check.connect("toggled", self.on_check)
        self.boot = 'none'
        boot = open(boot_file, 'w')
        boot.writelines(self.boot)
        boot.close()

        hbox = gtk.HBox()
        box2.pack_start(hbox, False, False, 10)
        #bbox.pack_start(label, False, True, 0)
        #bbox.pack_start(check, False, True, 0)
        hbox.pack_start(bbox, True, True, 50)
        label = gtk.Label()
        box2.pack_start(label, False, False, 0)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)

        box1.pack_start(box2, False, False, 0)

        box2.show()
        # Add button
        box2.pack_start(type_bbox(next, True,
                        10, gtk.BUTTONBOX_END),
                        True, True, 5)
        window.show_all()

partition_repos()
Types()
gtk.main()
