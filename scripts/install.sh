#!/usr/bin/env sh
set -eu

# shellcheck disable=SC3040
(set -o pipefail 2>/dev/null) && set -o pipefail

VERSION="{{version}}"
REPO="https://github.com/releasetools/bash/releases"

# Define URLs for the script and its checksum file
NAME="releasetools.bash"
readonly NAME
SCRIPT_URL="$REPO/download/$VERSION/$NAME"
readonly SCRIPT_URL

INSTALL_DIR="$HOME/.local/bin/releasetools/bash/$VERSION"
readonly INSTALL_DIR

# If the script doesn't exist, download it
if [ ! -r "$INSTALL_DIR/$NAME" ]; then
  mkdir -p "$INSTALL_DIR"

  # Download the script
  echo "Downloading the script and sha256 checksum from $SCRIPT_URL..." >&2
  if command -v curl >/dev/null 2>&1; then
    curl -sSL -o "$INSTALL_DIR/$NAME" "$SCRIPT_URL"
    curl -sSL -o "$INSTALL_DIR/$NAME.sha256" "$SCRIPT_URL.sha256"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$INSTALL_DIR/$NAME" "$SCRIPT_URL"
    wget -q -O "$INSTALL_DIR/$NAME.sha256" "$SCRIPT_URL.sha256"
  else
    echo "Error: curl or wget are needed to install the script." >&2
    exit 1
  fi

  # Check if the script was downloaded successfully
  if [ ! -f "$INSTALL_DIR/$NAME" ]; then
    echo "Error: Failed to download the script." >&2
    exit 1
  fi

  # Check if the checksum file was downloaded successfully
  if [ ! -f "$INSTALL_DIR/$NAME.sha256" ]; then
    echo "Error: Failed to download the checksum file." >&2
    exit 1
  fi

  # Perform checksum verification
  cwd="$(pwd -P)"
  cd "$INSTALL_DIR"
  sha256sum -c "$NAME.sha256" >&2 >/dev/null || (echo "Checksum verification failed!" >&2 && exit 1)
  cd "$cwd" # return to the previous directory

  echo "The releasetools module ($VERSION) has been downloaded and verified successfully." >&2
  echo >&2
  echo "You may now use it by sourcing it:" >&2
  echo ". '$INSTALL_DIR/$NAME'"
fi
