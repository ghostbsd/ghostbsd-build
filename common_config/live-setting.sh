#!/bin/sh

set -e -u

set_live_system()
{
  cp -Rf "${cwd}"/common_config/live-settings/base/override/root/* "${release}/root"
}
