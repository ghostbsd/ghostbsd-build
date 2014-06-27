#!/usr/bin/env python
# Copyright (c) 2011 GhostBSD
#
# See COPYING for licence terms.

import gtk
from subprocess import Popen

lyrics = """
 Please report to
, and be sure
to provide /tmp/.pc-sysinstall/pc-sysinstall.log.
"""


class PyApp:
    def on_reboot(self, widget):
        Popen('sudo reboot', shell=True)
        gtk.main_quit()

    def on_close(self, widget):
        gtk.main_quit()

    def __init__(self):
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        window.set_position(gtk.WIN_POS_CENTER)
        window.set_border_width(8)
        window.connect("destroy", gtk.main_quit)
        window.set_title("Installation Error")
        #window.set_icon_from_file("/usr/local/etc/gbi/logo.png")
        box1 = gtk.VBox(False, 0)
        window.add(box1)
        box1.show()
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        box1.pack_start(box2, True, True, 0)
        box2.show()
        title = gtk.Label()
        title.set_use_markup(True)
        title.set_markup('<b><span size="larger">Installation has failed!</span></b>')
        label = gtk.Label(lyrics)
        label.set_use_markup(True)

        label.set_markup("Please report the issue to <a href='http://issues.ghostbsd.org/my_view_page.php'>GhostBSD issue system</a>,\nand be sure to provide tmp/.pc-sysinstall/pc-sysinstall.log.")
        box2.pack_start(title)
        box2.pack_start(label)
        box2 = gtk.HBox(False, 10)
        box2.set_border_width(5)
        box1.pack_start(box2, False, True, 0)
        box2.show()
        table = gtk.Table(1, 2, True)
        ok = gtk.Button("Ok")
        ok.connect("clicked", self.on_close)
        table.attach(ok, 0, 2, 0, 1)

        box2.pack_start(table)
        window.show_all()

PyApp()
gtk.main()
