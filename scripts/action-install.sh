#!/usr/bin/env bash
#
# action-install.sh - helper script for installing releasetools/bash as part of a GitHub action
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

set -euo pipefail

if command -v curl >/dev/null 2>&1; then
  # shellcheck source=/dev/null
  . <(curl -sSL "https://github.com/releasetools/bash/releases/download/${VERSION}/install.sh")
elif command -v wget >/dev/null 2>&1; then
  # shellcheck source=/dev/null
  . <(wget -q -O- "https://github.com/releasetools/bash/releases/download/${VERSION}/install.sh")
else
  echo "ERROR: curl or wget are needed to install the script." >&2
  exit 1
fi

echo "Adding the install location to GITHUB_PATH" >&2
base::_symlink_binary_location >>"$GITHUB_PATH"
