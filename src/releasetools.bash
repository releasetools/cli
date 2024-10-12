#!/usr/bin/env bash
#
# releasetools.bash - Generic release tools and helpers
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Returns the version of the release tools.
function releasetools::version() {
  echo "{{version}}"
}

# Returns the absolute path of the install directory.
function releasetools::install_location() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

  echo "$dir"
}
