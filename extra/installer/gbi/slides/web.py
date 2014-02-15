#!/usr/bin/env python

import gtk
import webkit
import gobject


class Browser:
    default_site = "/usr/local/etc/gbi/slides/welcome.html"

    def delete_event(self, widget, event, data=None):
        return False

    def destroy(self, widget, data=None):
        gtk.main_quit()

    def __init__(self):
        gobject.threads_init()
        self.window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        self.window.set_resizable(True)
        self.window.set_size_request(770, 600)
        self.window.connect("delete_event", self.delete_event)
        self.window.connect("destroy", self.destroy)

        #webkit.WebView allows us to embed a webkit browser
        #it takes care of going backwards/fowards/reloading
        #it even handles flash
        self.web_view = webkit.WebView()
        self.web_view.open(self.default_site)

        scroll_window = gtk.ScrolledWindow()
        scroll_window.add(self.web_view)

        vbox = gtk.VBox(False, 0)
        vbox.add(scroll_window)

        self.window.add(vbox)
        self.window.show_all()

    def refresh(self, widget, data=None):
        '''Simple makes webkit reload the current back.'''
        self.web_view.reload()

Browser()
gtk.main()
