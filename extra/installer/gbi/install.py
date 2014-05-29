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
import gobject
import webkit
import threading
import locale
from subprocess import Popen, PIPE, STDOUT, call
from time import sleep
from partition_handler import rDeleteParttion, destroyParttion, makingParttion

tmp = "/home/ghostbsd/.gbi/"
gbi_path = "/usr/local/etc/gbi/"
sysinstall = "pc-sysinstall"

encoding = locale.getpreferredencoding()
utf8conv = lambda x: str(x, encoding).encode('utf8')
threadBreak = False
gobject.threads_init()


def close_application(self, widget):
    gtk.main_quit()


def read_output(command, window, probar):
    probar.set_text("Beginning installation")
    sleep(2)
    probar.set_text("Creating partition table")
    sleep(2)
    if os.path.exists(tmp + 'delete'):
        #new_val = probar.get_fraction() + 0.3
        probar.set_fraction(0.001)
        probar.set_text("Deleting partition")
        rDeleteParttion()
        sleep(5)
    # destroy disk partition and create scheme
    if os.path.exists(tmp + 'destroy'):
        #new_val = probar.get_fraction() + 0.3
        probar.set_fraction(0.002)
        probar.set_text("Creating new disk with partitions")
        destroyParttion()
        sleep(5)
    # create partition
    if os.path.exists(tmp + 'create'):
        #new_val = probar.get_fraction() + 0.4
        probar.set_fraction(0.003)
        probar.set_text("Creating new partitions")
        makingParttion()
        sleep(5)
    p = Popen(command, shell=True, stdin=PIPE, stdout=PIPE,
    stderr=STDOUT, close_fds=True)
    while 1:
        line = p.stdout.readline()
        if not line:
            break
        new_val = probar.get_fraction() + 0.000002
        probar.set_fraction(new_val)
        bartext = line
        probar.set_text("%s" % bartext.rstrip())
        filer = open("/home/ghostbsd/.gbi/tmp", "a")
        filer.writelines(bartext)
        filer.close
        print(bartext)
    probar.set_fraction(1.0)
    if bartext.rstrip() == "Installation Completed Successfully!":
        call('python %send.py' % gbi_path, shell=True, close_fds=True)
        gobject.idle_add(window.destroy)
    else:
        call('python %serror.py' % gbi_path, shell=True, close_fds=True)
        gobject.idle_add(window.destroy)


class Installs():
    default_site = "/usr/local/etc/gbi/slides/welcome.html"

    def close_application(self, widget):
        gtk.main_quit()

    def __init__(self):
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        window.connect("destroy", self.close_application)
        window.set_size_request(700, 500)
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
        #self.timer = gobject.timeout_add(150, progress_timeout, self.pbar)
        box2.pack_start(self.pbar, False, False, 0)
        web_view = webkit.WebView()
        web_view.open(self.default_site)
        sw = gtk.ScrolledWindow()
        sw.add(web_view)
        sw.show()
        box2.pack_start(sw, True, True, 0)
        window.show_all()
        command = '%s -c %spcinstall.cfg' % (sysinstall, tmp)
        # This is only for testing
        #command = 'cd /usr/ports/editors/openoffice-4 && make install clean'
        thr = threading.Thread(target=read_output,
         args=(command, window, self.pbar))
        thr.start()


Installs()
gtk.main()
