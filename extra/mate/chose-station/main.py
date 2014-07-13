#!/usr/local/bin/python

from gi.repository import Gtk
<<<<<<< HEAD
from subprocess import Popen, call

matePanel = '/usr/local/share/mate-panel/panel-default-layout.mate'
classicpng = '/usr/local/share/chose-station/classic.png'
puritypng = '/usr/local/share/chose-station/purity.png'
elementpng = '/usr/local/share/chose-station/element.png'
classicpanel = '/usr/local/share/chose-station/classic-panel'
puritypanel = '/usr/local/share/chose-station/purity-panel'
elementpanel = '/usr/local/share/chose-station/element-panel'
=======

>>>>>>> 0600fc0b0bf65eb2ecad26eae98163ae1329899d

class RadioButtonWindow(Gtk.Window):

    def __init__(self):
<<<<<<< HEAD
        Gtk.Window.__init__(self, title="Chose your WorkStation")
        self.set_border_width(1)
        self.set_resizable(False)
        vbox = Gtk.VBox()
        hbox = Gtk.HBox(spacing=6)
        self.add(vbox)
        vbox.pack_start(hbox, False, False, 0)
        button1 = Gtk.RadioButton.new_with_label_from_widget(None,
        "Classic Station")
        button1.connect("toggled", self.on_button_toggled, "classic")
        button1.show()
        hbox.pack_start(button1, False, False, 0)
        classic = Gtk.Image()
        classic.set_from_file(classicpng)
        button2 = Gtk.RadioButton.new_with_label_from_widget(button1,
        "Purity Station")
        button2.connect("toggled", self.on_button_toggled, "purity")
        button2.show()
        hbox.pack_start(button2, False, False, 0)
        purity = Gtk.Image()
        purity.set_from_file(puritypng)
        button3 = Gtk.RadioButton.new_with_label_from_widget(button1,
        "Element Station")
        button3.connect("toggled", self.on_button_toggled, "element")
        button3.show()
        hbox.pack_start(button3, False, False, 0)
        element = Gtk.Image()
        element.set_from_file(elementpng)
        hbox = Gtk.HBox(spacing=6)
        vbox.pack_start(hbox, False, False, 0)
        check_numeric = Gtk.CheckButton("Composit")
        check_numeric.connect("toggled", self.on_numeric_toggled)
        #hbox.pack_start(check_numeric, True, True, 30)
        check_ifvalid = Gtk.CheckButton("Transparent")
        check_ifvalid.connect("toggled", self.on_ifvalid_toggled)
        #hbox.pack_start(check_ifvalid, True, True, 30)
        grid = Gtk.Table(1, 4, True)
        #grid.attach(Apply, 2, 3, 0, 1)
        #grid.attach(Close, 3, 4, 0, 1)
        #hbox.pack_start(grid, True, True, 0)
        hbox = Gtk.HBox(spacing=6)
        vbox.pack_start(hbox, False, False, 0)
        Apply = Gtk.Button(stock=Gtk.STOCK_APPLY)
        Apply.connect("clicked", self.on_apply_clicked)
        Close = Gtk.Button(stock=Gtk.STOCK_CLOSE)
        Close.connect("clicked", self.on_close_clicked)

        grid.attach(Apply, 2, 3, 0, 1)
        grid.attach(Close, 3, 4, 0, 1) 
        hbox.pack_start(grid, True, True, 0)
        self.show_all()
        
    def on_close_clicked(self, widget):
        call(
        'sudo rm /usr/local/etc/xdg/autostart/chose-station.desktop',
        shell=True)
        Gtk.main_quit()
    
    def on_button_toggled(self, button, name):
        self.pname = name
        
    def on_apply_clicked(self, widget):
        if self.pname == 'classic':
            call('sudo cp ' + classicpanel + ' ' + matePanel, shell=True)
        elif self.pname == 'purity':
            call('sudo cp ' + puritypanel + ' ' + matePanel, shell=True)
        elif self.pname == 'element':
            call('sudo cp ' + elementpanel + ' ' + matePanel, shell=True)
        call('mate-panel --reset', shell=True)
        call('killall mate-panel', shell=True)
        Popen('mate-panel', shell=True)
        if self.pname == 'element':
            call(
            'sudo cp /usr/local/share/applications/plank.desktop /usr/local/etc/xdg/autostart/plank.desktop',
            shell=True)
            Popen('plank', shell=True)
            
        elif self.pname != 'element':
            call('sudo rm /usr/local/etc/xdg/autostart/plank.desktop')
            call('killall plank', shell=True)
            
    def on_numeric_toggled(self, button):
        self.spinbutton.set_numeric(button.get_active())

    def on_ifvalid_toggled(self, button):
        if button.get_active():
            policy = Gtk.SpinButtonUpdatePolicy.IF_VALID
        else:
            policy = Gtk.SpinButtonUpdatePolicy.ALWAYS
        self.spinbutton.set_update_policy(policy)
=======
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

>>>>>>> 0600fc0b0bf65eb2ecad26eae98163ae1329899d

win = RadioButtonWindow()
win.connect("delete-event", Gtk.main_quit)
win.show_all()
Gtk.main()
