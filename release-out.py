#!/usr/local/bin/python

import pexpect
from subprocess import call
import getpass

i386 = "/usr/obj/i386"
amd64 = "/usr/obj/amd64"
server = "frs.sourceforge.net"
user = raw_input("username: ")
password = getpass.getpass("Password: ")

call('cd /usr/obj && ls GhostBSD*i386* > %s' % i386, shell=True)
call('cd /usr/obj && ls GhostBSD*amd64* > %s' % amd64, shell=True)

release = open(i386, "r")
for line in release.readlines():
    foo = pexpect.spawn('scp /usr/obj/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/i386/4.0/%s'
    % (line.strip(), user, server, line.strip()))
    foo.expect('Password:')
    foo.sendline(password)
    foo.interact()

release = open(amd64, "r")
for line in release.readlines():
    foo = pexpect.spawn('scp /usr/obj/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/amd64/4.0/%s'
    % (line.strip(), user, server, line.strip()))
    foo.expect('Password:')
    foo.sendline(password)
    foo.interact()
