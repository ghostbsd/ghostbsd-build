#!/usr/local/bin/python

import pexpect
from subprocess import Popen, PIPE
from getpass import getpass

i386 = "/usr/obj/i386"
amd64 = "/usr/obj/amd64"
server = "frs.sourceforge.net"
user = raw_input("username: ")
password = getpass("Password: ")

i386 = Popen('cd /usr/obj && ls GhostBSD*i386*', stdout=PIPE, shell=True)
amd64 = Popen('cd /usr/obj && ls GhostBSD*amd64*', stdout=PIPE, shell=True)


for line in i386.stdout.readlines():
    foo = pexpect.spawn(
    'scp /usr/obj/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/i386/4.0/%s'
    % (line.strip(), user, server, line.strip()))
    foo.expect('Password:')
    foo.sendline(password)
    foo.interact()

for line in amd64.stdout.readlines():
    foo = pexpect.spawn(
    'scp /usr/obj/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/amd64/4.0/%s'
    % (line.strip(), user, server, line.strip()))
    foo.expect('Password:')
    foo.sendline(password)
    foo.interact()
