#!/usr/bin/env python
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.

import gtk
from subprocess import Popen

lyrics = """Installation is complete. You need to restart the
computer in order to use the new installation.
You can continue to use this live media, although
any changes you make or document you save will
not be preserved."""


class PyApp(gtk.Window):
    def on_reboot(self, widget):
        Popen('sudo reboot', shell=True)
        gtk.main_quit()

    def on_close(self, widget):
        gtk.main_quit()

    def __init__(self):
        window = gtk.Window()
        window.set_position(gtk.WIN_POS_CENTER)
        window.set_border_width(8)
        window.connect("destroy", gtk.main_quit)
        window.set_title("Installation completed")
        window.set_icon_from_file("/usr/local/etc/gbi/logo.png")
        box1 = gtk.VBox(False, 0)
        window.add(box1)
        box1.show()
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        box1.pack_start(box2, True, True, 0)
        box2.show()
        label = gtk.Label(lyrics)
        box2.pack_start(label)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, True, 0)
        box2.show()
        table = gtk.Table(1, 2, True)
        restart = gtk.Button("Restart")
        restart.connect("clicked", self.on_reboot)
        Continue = gtk.Button("Continue")
        Continue.connect("clicked", self.on_close)
        table.attach(Continue, 0, 1, 0, 1)
        table.attach(restart, 1, 2, 0, 1)
        box2.pack_start(table)
        window.show_all()

PyApp()
gtk.main()
