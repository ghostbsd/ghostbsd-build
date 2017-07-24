#!/usr/local/bin/python
#####################################################################
# Copyright (c) 2015, GhostBSD. All rights reserved.
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
# 3. Neither then name of GhostBSD nor the names of its
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

import pexpect
from subprocess import Popen, PIPE, call
from getpass import getpass
from os import path
from sys import argv
import getopt


try:
    myopts, args = getopt.getopt(argv[1:], "r:v:")
except getopt.GetoptError as e:
    print (str(e))
    print("Usage: %s -r release -v version" % argv[0])
    exit()

for output, arg in myopts:
    if output == '-r':
        release = arg
    elif output == '-v':
        version = arg

i386 = "/usr/obj/i386"
amd64 = "/usr/obj/amd64"
#version = '11.0'
vrpath = version + "-" + release
i386path = "/usr/local/www/ftp/pub/GhostBSD/releases/i386/ISO-IMAGES/" + vrpath + "/"
amd64path = "/usr/local/www/ftp/pub/GhostBSD/releases/amd64/ISO-IMAGES/" + vrpath + "/"
server = "ghostbsd.org"
# Get username
user = "root"

host = user + "@" + server
# user = raw_input("SourceForge username: ")
# Get username
password = getpass("Enter passphrase: ")

call("ssh " + host + " 'mkdir -p " + i386path + "'", shell=True)
call("ssh " + host + " 'mkdir -p " + amd64path + "'", shell=True)


if path.isdir('/usr/obj/i386/mate'):
    matei386 = Popen('cd /usr/obj/i386/mate && ls GhostBSD%s*i386*' % version,
                     stdout=PIPE, shell=True)
    for line in matei386.stdout.readlines():
        foo = pexpect.spawn('scp /usr/obj/i386/mate/' + line.strip() + ' ' + host + ":" + i386path + line.strip())
        foo.expect('Enter passphrase')
        foo.sendline(password)
        foo.interact()

if path.isdir('/usr/obj/amd64/mate'):
    mateamd64 = Popen('cd /usr/obj/amd64/mate && ls GhostBSD%s*amd64*' % version, stdout=PIPE, shell=True)
    for line in mateamd64.stdout.readlines():
        foo = pexpect.spawn('scp /usr/obj/amd64/mate/' + line.strip() + ' ' + host + ":" + amd64path + line.strip())
        foo.expect('Enter passphrase')
        foo.sendline(password)
        foo.interact()

if path.isdir('/usr/obj/i386/xfce'):
    xfcei386 = Popen('cd /usr/obj/i386/xfce && ls GhostBSD%s*i386*' % version,
                     stdout=PIPE, shell=True)
    for line in xfcei386.stdout.readlines():
        foo = pexpect.spawn('scp /usr/obj/i386/xfce/' + line.strip() + ' ' + host + ":" + i386path + line.strip())
        foo.expect('Enter passphrase')
        foo.sendline(password)
        foo.interact()

if path.isdir('/usr/obj/amd64/xfce'):
    xfceamd64 = Popen('cd /usr/obj/amd64/xfce && ls GhostBSD%s*amd64*' % version, stdout=PIPE, shell=True)
    for line in xfceamd64.stdout.readlines():
        foo = pexpect.spawn('scp /usr/obj/amd64/xfce/' + line.strip() + ' ' + host + ":" + amd64path + line.strip())
        foo.expect('Enter passphrase')
        foo.sendline(password)
        foo.interact()
