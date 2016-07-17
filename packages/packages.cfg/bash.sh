#!/bin/sh

# add fdescfs to /etc/fstab
echo "fdesc	/dev/fd		fdescfs		rw	0	0" >> /etc/fstab
