#!/usr/local/bin/python

import gtk
import urllib2
import urllib
import os

HTMLINDEX = urllib2.urlopen('https://sourceforge.net/projects/ghostbsdproject/files/update/2.5/index/')
HTML = HTMLINDEX.readlines()

if os.path.exists('/var/db/gbu/index'):
    INDEX = open('/var/db/gbu/index', 'r')
    INDEX = INDEX.readlines() 
    if INDEX:
        if HTML[-1] > INDEX[-1]:
            REMOVE = INDEX
            START = HTML
            KEEP = []
            for WORD in START:
                if WORD not in REMOVE:
                    KEEP.append(WORD)
                    print KEEP
        else:
            EXIT = 'quit()'
else:
    KEEP = HTML
try:
    EXIT
except NameError:
    for KEEP in KEEP:
        url = "https://sourceforge.net/projects/ghostbsdproject/files/update/2.5/%s" % KEEP.rstrip()
        
        file_name = KEEP.rstrip()
        urllib.urlretrieve (url, file_name)
        u = urllib2.urlopen(url)
        meta = u.info()
        file_size = int(meta.getheaders("Content-Length")[0])

        file_size_dl = 0
        block_sz = file_size
        while True:
            buffer = u.read(file_size)
            if not buffer:
                break

        file_size_dl += len(buffer)
        
        status = '[100.00%]'
        print "Downloading: %s Bytes: %s %s" % (file_name, file_size, status)
        
else:
   EXIT

