#!/bin/sh

set -e -u

set_live_system()
{
  cp -Rf ${cwd}/systems/trueos/extra/common-live-settings/base/override/root/* ${release}/root
}
