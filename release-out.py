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
from subprocess import Popen, PIPE
from getpass import getpass
from os import path
i386 = "/usr/obj/i386"
amd64 = "/usr/obj/amd64"
release = '11.0'
server = "frs.sourceforge.net"
# Get username
user = raw_input("SourceForge username: ")
# Get username
password = getpass("SourceForge Password: ")


if path.isdir('/usr/obj/i386/mate'):
    matei386 = Popen('cd /usr/obj/i386/mate && ls GhostBSD%s*i386*' % release, stdout=PIPE, shell=True)
    for line in matei386.stdout.readlines():
        foo = pexpect.spawn(
        'scp /usr/obj/i386/mate/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/i386/10.3/mate/%s'
        % (line.strip(), user, server, line.strip()))
        foo.expect('Password:')
        foo.sendline(password)
        foo.interact()

if path.isdir('/usr/obj/amd64/mate'):
    mateamd64 = Popen('cd /usr/obj/amd64/mate && ls GhostBSD%s*amd64*' % release, stdout=PIPE, shell=True)
    for line in mateamd64.stdout.readlines():
        foo = pexpect.spawn(
        'scp /usr/obj/amd64/mate/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/amd64/10.3/mate/%s'
        % (line.strip(), user, server, line.strip()))
        foo.expect('Password:')
        foo.sendline(password)
        foo.interact()

if path.isdir('/usr/obj/i386/xfce'):
    xfcei386 = Popen('cd /usr/obj/i386/xfce && ls GhostBSD%s*i386*' % release, stdout=PIPE, shell=True)
    for line in xfcei386.stdout.readlines():
        foo = pexpect.spawn(
        'scp /usr/obj/i386/xfce/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/i386/10.3/xfce/%s'
        % (line.strip(), user, server, line.strip()))
        foo.expect('Password:')
        foo.sendline(password)
        foo.interact()

if path.isdir('/usr/obj/amd64/xfce'):
    xfceamd64 = Popen('cd /usr/obj/amd64/xfce && ls GhostBSD%s*i386*' % release, stdout=PIPE, shell=True)
    for line in xfceamd64.stdout.readlines():
        foo = pexpect.spawn(
        'scp /usr/obj/amd64/xfce/%s %s@%s:/home/frs/project/g/gh/ghostbsdproject/release/amd64/10.3/xfce/%s'
        % (line.strip(), user, server, line.strip()))
        foo.expect('Password:')
        foo.sendline(password)
        foo.interact()
