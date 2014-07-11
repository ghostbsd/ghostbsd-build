#!/usr/local/bin/python

from gi.repository import Gtk


class RadioButtonWindow(Gtk.Window):

    def __init__(self):
        Gtk.Window.__init__(self, title="Chose your Station")
        self.set_border_width(1)
        self.set_resizable(False)
        grid = Gtk.Table(6, 6, False)
        self.add(grid)
        button1 = Gtk.RadioButton.new_with_label_from_widget(None,
        "Classic Station")
        button1.connect("toggled", self.on_button_toggled, "classic")
        classic = Gtk.Image()
        classic.set_from_file('/home/ericbsd/classic.png')
        button2 = Gtk.RadioButton.new_from_widget(button1)
        button2.set_label("Purity Station")
        button2.connect("toggled", self.on_button_toggled, "purity")
        purity = Gtk.Image()
        purity.set_from_file('/home/ericbsd/purity.png')
        button3 = Gtk.RadioButton.new_with_mnemonic_from_widget(button1,
        "Element Station")
        button3.connect("toggled", self.on_button_toggled, "element")
        element = Gtk.Image()
        element.set_from_file('/home/ericbsd/element.png')
        grid.attach(button1, 1, 3, 0, 1)
        Apply = Gtk.Button(stock=Gtk.STOCK_APPLY)
        #button.connect("clicked", self.on_apply_clicked)

        Close = Gtk.Button(stock=Gtk.STOCK_CLOSE)
        #button.connect("clicked", self.on_close_clicked)

        grid.attach(classic, 3, 5,  0, 1)
        grid.attach(button2, 1, 3, 1, 2)
        grid.attach(purity, 3, 5, 1, 2)
        grid.attach(button3, 1, 3, 2, 3)
        grid.attach(element, 3, 5, 2, 3)
        grid.attach(Apply, 3, 4, 3, 4)
        grid.attach(Close, 4, 5, 3, 4)
        self.show_all()

    def on_button_toggled(self, button, name):
        if name == 'classic':
            pass
        elif name == 'purity':
            pass
        elif name == 'element':
            pass


win = RadioButtonWindow()
win.connect("delete-event", Gtk.main_quit)
win.show_all()
Gtk.main()
