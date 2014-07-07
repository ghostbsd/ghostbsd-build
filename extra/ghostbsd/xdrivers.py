#!/usr/local/bin/python

import curses
from os import system

xorg = '/etc/X11/xorg.conf'
newxorg = '/etc/X11/xorg.conf.new'


def driversList():
    xfile = open(xorg, 'r')
    xdriver = []
    for line in xfile.readlines():
        nline = line.rstrip()
        if 'Driver' in nline:
            if 'kbd' in nline or 'mouse' in nline or '#' in nline:
                pass
            else:
                xdriver.append(nline.split()[1])
    xfile.close()
    return xdriver


def changeDrivers(num):
    xfile = open(xorg, 'r')
    newxf = open(newxorg, 'w')
    dr1 = driversList()[0]
    dr2 = driversList()[num]
    for line in xfile.readlines():
        if dr1 in line:
            newxf.writelines('	Driver	      %s\n' % dr2)
        elif dr2 in line:
            newxf.writelines('	Driver	      %s\n' % dr1)
        else:
            newxf.writelines("%s" % line)
    xfile.close()
    newxf.close()
    system('cp %s %s' % (newxorg, xorg))


def Main():
    x = 0
    while x != ord('q'):
        screen.clear()
        screen.border()
        screen.addstr(1, 20, "Quick Graphics Drivers Configuration")
        screen.addstr(3, 20, "Your current driver is " + driversList()[0])
        screen.addstr(5, 20, "Please choose a drivers to start X:")
        if len(driversList()) == 2:
            screen.addstr(7, 25, "1 - %s driver" % driversList()[0])
            screen.addstr(8, 25, "2 - %s driver" % driversList()[1])
            screen.addstr(10, 25, "Q - Exit")
        else:
            screen.addstr(7, 25, "1 - %s driver" % driversList()[0])
            screen.addstr(8, 25, "2 - %s driver" % driversList()[1])
            screen.addstr(9, 25, "3 - %s driver" % driversList()[2])
            screen.addstr(11, 25, "Q - Exit")
        screen.addstr(15, 16, "This Driver will be save for future session")
        x = screen.getch()
        if x == ord('1'):
            changeDrivers(0)
            curses.endwin()
            system('gdm')
        if x == ord('2'):
            changeDrivers(1)
            curses.endwin()
            system('gdm')
        if len(driversList()) == 2:
            if x == ord('3'):
                changeDrivers(2)
                curses.endwin()
                system('gdm')
    curses.endwin()
    system('clear')
screen = curses.initscr()
Main()