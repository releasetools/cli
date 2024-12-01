#!/usr/bin/env sh
#
# install.sh - downloads and installs the specified releasetools/cli version
#              in a local environment
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

set -eu

# shellcheck disable=SC3040
(set -o pipefail 2>/dev/null) && set -o pipefail

VERSION="{{version}}"

# The source repository URL
REPO="https://github.com/releasetools/cli/releases"
readonly REPO
# The name of the project
PROJECT_PATH="releasetools/cli"
readonly PROJECT_PATH
# The name of the distributed script
NAME="releasetools.bash"
readonly NAME
# The name of the symlinked executable that will be run by users
EXEC_NAME="rt"
readonly EXEC_NAME

# Define URLs for the script and its checksum file
SCRIPT_URL="$REPO/download/$VERSION/$NAME"
readonly SCRIPT_URL

# Allow customizing the install location
INSTALL_DIR="${RELEASETOOLS_INSTALL_DIR-}"
if [ -z "${INSTALL_DIR-}" ]; then
  # Set a default value, if the variable is not set
  INSTALL_DIR="$HOME/.local/share/$PROJECT_PATH/$VERSION"
fi

# Ensure the directory exists
if [ ! -d "$INSTALL_DIR" ]; then
  mkdir -p "$INSTALL_DIR" >&2
fi

# Ensure the variable is resolved to the absolute path
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd -P)"
readonly INSTALL_DIR

# If the script doesn't exist, download it
if [ ! -r "$INSTALL_DIR/$NAME" ]; then
  # Download the script
  echo "Downloading the script and sha256 checksum from $SCRIPT_URL..." >&2
  if command -v curl >/dev/null 2>&1; then
    curl -sSL -o "$INSTALL_DIR/$NAME" "$SCRIPT_URL" >&2
    curl -sSL -o "$INSTALL_DIR/$NAME.sha256" "$SCRIPT_URL.sha256" >&2
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$INSTALL_DIR/$NAME" "$SCRIPT_URL" >&2
    wget -q -O "$INSTALL_DIR/$NAME.sha256" "$SCRIPT_URL.sha256" >&2
  else
    echo "ERROR: curl or wget are needed to install the script." >&2
    exit 1
  fi

  # Check if the script was downloaded successfully
  if [ ! -f "$INSTALL_DIR/$NAME" ]; then
    echo "ERROR: Failed to download the script." >&2
    exit 1
  fi

  # Check if the checksum file was downloaded successfully
  if [ ! -f "$INSTALL_DIR/$NAME.sha256" ]; then
    echo "ERROR: Failed to download the checksum file." >&2
    exit 1
  fi

  # Perform checksum verification
  cwd="$(pwd -P)"
  cd "$INSTALL_DIR" >&2
  sha256sum -c "$NAME.sha256" >&2 >/dev/null || (echo "Checksum verification failed!" >&2 && exit 1)
  cd "$cwd" >&2 # return to the previous directory

  # Make the script executable
  chmod +x "$INSTALL_DIR/$NAME" >&2

  echo "$PROJECT_PATH/$VERSION has been downloaded and verified successfully." >&2
  echo "It was installed at: $INSTALL_DIR/$NAME" >&2
  echo "" >&2
fi

# Source releasetools/cli
# shellcheck source=/dev/null
. "$INSTALL_DIR/$NAME"

# Symlink the binary
BINARY_DIR="$(base::_symlink_binary_location)"
readonly BINARY_DIR

# Ensure the directory exists
if [ ! -d "$BINARY_DIR" ]; then
  mkdir -p "$BINARY_DIR" >&2
fi

echo "Linking binary to $BINARY_DIR/$EXEC_NAME..." >&2
ln -sf "$INSTALL_DIR/$NAME" "$BINARY_DIR/$EXEC_NAME" >&2

# Output the location of the installed script
# allowing calling scripts to find it
echo "$INSTALL_DIR/$NAME"
