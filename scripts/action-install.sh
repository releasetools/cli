#!/usr/bin/env bash
#
# action-install.sh - helper script for installing releasetools/cli as part of a GitHub action
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

set -eu

# shellcheck disable=SC3040
(set -o pipefail 2>/dev/null) && set -o pipefail

# Download the install script
installer="$(mktemp)"
if command -v curl >/dev/null 2>&1; then
  curl -sSL "https://github.com/releasetools/cli/releases/download/${VERSION}/install.sh" -o "$installer"
elif command -v wget >/dev/null 2>&1; then
  # shellcheck source=/dev/null
  wget -q -O "$installer" "https://github.com/releasetools/cli/releases/download/${VERSION}/install.sh"
else
  echo "ERROR: curl or wget are needed to install the script." >&2
  exit 1
fi

# Run the installer
# shellcheck source=/dev/null
. "$installer"
rm -f "$installer"

# Determine the location where the binary was installed
binary_dir="$(base::_symlink_binary_location)"
readonly binary_dir

echo "Adding the binary location ($binary_dir) to GITHUB_PATH" >&2
echo "$binary_dir" >>"$GITHUB_PATH"
