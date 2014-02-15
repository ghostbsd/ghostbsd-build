#!/usr/bin/env python
#
# Copyright (c) 2013 GhostBSD
#
# See COPYING for licence terms.
#
# install.py v 0.4 Thursday, March 28 2013 19:54 Eric Turgeon
#
# install.py give the job to pc-sysinstall to install GhostBSD.

import gtk
import os
import gobject
import threading
import locale
from time import sleep
from partition_handler import rDeleteParttion, destroyParttion, makingParttion
from subprocess import Popen

tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
sysinstall = "pc-sysinstall"
to_root = 'python %sroot.py' % installer

encoding = locale.getpreferredencoding()
utf8conv = lambda x: str(x, encoding).encode('utf8')
threadBreak = False
gobject.threads_init()


def read_output(window, probar):
    probar.set_text("Preparing partition")
    sleep(2)
    if os.path.exists(tmp + 'delete'):
        #new_val = probar.get_fraction() + 0.3
        probar.set_fraction(0.3)
        probar.set_text("Deleting partition")
        rDeleteParttion()
        sleep(5)
    # destroy disk partition and create scheme
    if os.path.exists(tmp + 'destroy'):
        #new_val = probar.get_fraction() + 0.3
        probar.set_fraction(0.3)
        probar.set_text("Creating new disk with partitions")
        destroyParttion()
        sleep(5)
    # create partition
    if os.path.exists(tmp + 'create'):
        #new_val = probar.get_fraction() + 0.4
        probar.set_fraction(0.4)
        probar.set_text("Creating new partitions")
        makingParttion()
        sleep(5)
    probar.set_text("Finish")
    probar.set_fraction(1.0)
    sleep(1)
    Popen(to_root, shell=True)
    gobject.idle_add(window.destroy)


class Installs():
    default_site = "/usr/local/etc/gbi/slides/welcome.html"

    def close_application(self, widget):
        gtk.main_quit()

    def __init__(self):
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        window.connect("destroy", self.close_application)
        window.set_size_request(400, 200)
        window.set_title("Installation")
        window.set_resizable(False)
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
        self.pbar = gtk.ProgressBar()
        self.pbar.set_orientation(gtk.PROGRESS_LEFT_TO_RIGHT)
        self.pbar.set_fraction(0.0)
        self.pbar.set_size_request(-1, 20)
        box2.pack_start(self.pbar, False, False, 0)
        #box2.pack_start(sw, True, True, 0)
        window.show_all()
        thr = threading.Thread(target=read_output,
        args=(window, self.pbar))
        thr.start()

Installs()
gtk.main()