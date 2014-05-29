#!/usr/bin/env python
#
#####################################################################
# Copyright (c) 2010-2013, GhostBSD. All rights reserved.
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
# $Id: defutil.py v 0.1 Fryday, March 29 2013 15:19 Eric Turgeon $

# defutil.py define all repetitive def for the the installer.

import gtk
import os.path
from subprocess import Popen, call
import shutil

# installer python script path
tmp = "/home/ghostbsd/.gbi/"
installer = "/usr/local/etc/gbi/"
time = '%stimezone' % tmp
signal = '%ssignal' % tmp

# script to starts
to_language = 'python %slanguage.py' % installer
to_keyboard = 'python %skeyboard.py' % installer
to_time = 'python %stimezone.py' % installer
to_type = 'python %stype.py' % installer
to_upgrade = 'python %stype.py' % installer
to_use_disk = 'python %suse_disk.py' % installer
to_partition = 'python %spartition.py' % installer
to_label = 'python %slabel.py' % installer
to_root = 'python %sroot.py' % installer
to_user = 'python %suser.py' % installer
Part_label = '%spartlabel' % tmp
to_prepart = 'python %sprepart.py' % installer


# Function to close window.
def close_application(widget):
    if os.path.exists(tmp):
        shutil.rmtree(tmp)
    call("setxkbmap us", shell=True)
    gtk.main_quit()


# Function to go next.
def keyboard_window(widget):
    Popen(to_keyboard, shell=True)
    gtk.main_quit()


def language_window(widget):
    Popen(to_language, shell=True)
    call("setxkbmap us", shell=True)
    gtk.main_quit()


def time_window(widget):
    Popen(to_time, shell=True)
    call("setxkbmap us", shell=True)
    gtk.main_quit()


def type_window(widget):
    if os.path.exists(time):
        Popen(to_type, shell=True)
        gtk.main_quit()


def disk_window(widget, nxt):
    read_file = open(signal, 'r')
    nxt = read_file.read()
    if nxt == 'user':
        Popen(to_use_disk, shell=True)
        gtk.main_quit()
    elif nxt == 'custom':
        Popen(to_partition, shell=True)
        gtk.main_quit()


def custom_window(widget):
        Popen(to_partition, shell=True)
        gtk.main_quit()


def root_window(widget):
    partlabel = '%spartlabel' % tmp
    answer = None
    for line in part:
        if '/ ' in line:
            answer = True
            break
        else:
            pass
    if answer is True:
        Popen(to_root, shell=True)
        gtk.main_quit()
    elif answer is None:
        # Need to make a dialog box for root file system not 
        pass

def noRootFs(widget):
    md = gtk.MessageDialog(self, 
    gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_WARNING, 
    gtk.BUTTONS_CLOSE, "Root(/) file system is missing")
    md.run()
    md.destroy()


def back_window(widget):
    read_file = open(signal, 'r')
    nxt = read_file.readlines()[0].rstrip()
    if nxt == 'user':
        Popen(to_use_disk, shell=True)
        gtk.main_quit()
    elif nxt == 'custom':
        Popen(to_label, shell=True)
        gtk.main_quit()


def label_window(widget):
    Popen(to_label, shell=True)
    gtk.main_quit()


def root_window(widget):
    Popen(to_root, shell=True)
    gtk.main_quit()


def user_window(widget):
    Popen(to_user, shell=True)
    gtk.main_quit()


def language_bbox(horizontal, spacing, layout):
    bbox = gtk.HButtonBox()
    bbox.set_border_width(5)
    bbox.set_layout(layout)
    bbox.set_spacing(spacing)
    button = gtk.Button(stock=gtk.STOCK_CANCEL)
    bbox.add(button)
    button.connect("clicked", close_application)
    button = gtk.Button(stock=gtk.STOCK_GO_FORWARD)
    bbox.add(button)
    button.connect("clicked", keyboard_window)
    return bbox


def Keyboard_bbox(horizontal, spacing, layout):
    bbox = gtk.HButtonBox()
    bbox.set_border_width(5)
    bbox.set_layout(layout)
    bbox.set_spacing(spacing)
    button = gtk.Button(stock=gtk.STOCK_GO_BACK)
    bbox.add(button)
    button.connect("clicked", language_window)
    button = gtk.Button(stock=gtk.STOCK_CANCEL)
    bbox.add(button)
    button.connect("clicked", close_application)
    button = gtk.Button(stock=gtk.STOCK_GO_FORWARD)
    bbox.add(button)
    button.connect("clicked", time_window)
    return bbox


def time_bbox(horizontal, spacing, layout):
    bbox = gtk.HButtonBox()
    bbox.set_border_width(5)
    bbox.set_layout(layout)
    bbox.set_spacing(spacing)
    button = gtk.Button(stock=gtk.STOCK_GO_BACK)
    bbox.add(button)
    button.connect("clicked", keyboard_window)
    button = gtk.Button(stock=gtk.STOCK_CANCEL)
    bbox.add(button)
    button.connect("clicked", close_application)
    button = gtk.Button(stock=gtk.STOCK_GO_FORWARD)
    bbox.add(button)
    button.connect("clicked", type_window)
    return bbox


def type_bbox(Next, horizontal, spacing, layout):
    bbox = gtk.HButtonBox()
    bbox.set_border_width(5)
    bbox.set_layout(layout)
    bbox.set_spacing(spacing)
    button = gtk.Button(stock=gtk.STOCK_GO_BACK)
    bbox.add(button)
    button.connect("clicked", time_window)
    button = gtk.Button(stock=gtk.STOCK_CANCEL)
    bbox.add(button)
    button.connect("clicked", close_application)
    button = gtk.Button(stock=gtk.STOCK_GO_FORWARD)
    bbox.add(button)
    button.connect("clicked", disk_window, Next)
    return bbox


def use_disk_bbox(horizontal, spacing, layout):
    bbox = gtk.HButtonBox()
    bbox.set_border_width(5)
    bbox.set_layout(layout)
    bbox.set_spacing(spacing)
    button = gtk.Button(stock=gtk.STOCK_GO_BACK)
    bbox.add(button)
    button.connect("clicked", type_window)
    button = gtk.Button(stock=gtk.STOCK_CANCEL)
    bbox.add(button)
    button.connect("clicked", close_application)
    button = gtk.Button(stock=gtk.STOCK_GO_FORWARD)
    bbox.add(button)
    button.connect("clicked", root_window)
    return bbox


def partition_bbox(horizontal, spacing, layout):
    bbox = gtk.HButtonBox()
    bbox.set_border_width(5)
    bbox.set_layout(layout)
    bbox.set_spacing(spacing)
    button = gtk.Button(stock=gtk.STOCK_GO_BACK)
    bbox.add(button)
    button.connect("clicked", type_window)
    button = gtk.Button(stock=gtk.STOCK_CANCEL)
    bbox.add(button)
    button.connect("clicked", close_application)
    button = gtk.Button(stock=gtk.STOCK_GO_FORWARD)
    bbox.add(button)
    button.connect("clicked", root_window)
    return bbox
