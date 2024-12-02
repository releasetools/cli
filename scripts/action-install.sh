#!/usr/bin/env bash
#
# action-install.sh - helper script for installing releasetools/cli as part of a GitHub action
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

set -euo pipefail

if command -v curl >/dev/null 2>&1; then
  echo "curl is available, downloading the script ($VERSION)..." >&2
  # shellcheck source=/dev/null
  . <(curl -sSL "https://github.com/releasetools/cli/releases/download/${VERSION}/install.sh")
elif command -v wget >/dev/null 2>&1; then
  echo "wget is available, downloading the script ($VERSION)..." >&2
  # shellcheck source=/dev/null
  . <(wget -q -O- "https://github.com/releasetools/cli/releases/download/${VERSION}/install.sh")
else
  echo "ERROR: curl or wget are needed to install the script." >&2
  exit 1
fi

# Determine the location where the binary was installed
binary_dir="${RELEASETOOLS_BINARY_DIR:-$HOME/.local/bin}"
readonly binary_dir

echo "Adding the binary location ($binary_dir) to GITHUB_PATH" >&2
echo "$binary_dir" >>"$GITHUB_PATH"
