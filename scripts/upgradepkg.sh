#!/bin/sh
#    Author: Eric Turgeon
# Copyright: 2014 GhostBSD
#
# Update and create package for GhostBSD

pkgaddcmd="pkg upgrade -y"

# Update GhostBSD pkg
$pkgaddcmd
