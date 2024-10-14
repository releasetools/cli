#!/usr/bin/env bash
#
# releasetools.bash - Generic release tools and helpers
#
# NOTE: This module should be considered as an internal module
#       and not meant as a generic catch-all module for functions
#       without a namespaace.
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function base::internal_check_deps() {
  return 0
}

# Returns the version of the release tools.
function base::version() {
  echo "{{version}}"
}

# Returns the absolute path to where the release tools have been installed.
function base::install_location() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  echo "$dir"
}

# Returns the path to a directory where the binaries should be symlinked.
function base::_symlink_binary_location() {
  local dir

  # Allow customizing the binaries' location
  dir="${RELEASETOOLS_BINARY_DIR-}"
  if [ -z "${dir-}" ]; then
    # Set a default value, if the variable is not set
    dir="$HOME/.local/bin"
  fi

  # Ensure the directory exists
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir" >&2
  fi

  # Ensure the variable is resolved to the absolute path
  dir="$(cd "$dir" && pwd -P)"
  echo "$dir"
}
