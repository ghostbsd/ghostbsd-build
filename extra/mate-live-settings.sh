#!/bin/sh

set -e -u

mate_schemas()
{
  mkdir -p ${release}/usr/local/share/glib-2.0/schemas
  cp extra/mate-live-settings/schemas/* ${release}/usr/local/share/glib-2.0/schemas
  chroot ${release} glib-compile-schemas /usr/local/share/glib-2.0/schemas
}
