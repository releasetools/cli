#!/usr/bin/env bash
#
# generate-install.sh - generates the install.sh script
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

set -euo pipefail

# Set the base directory as the parent of the current script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd -P)"
readonly DIR

# Output directory
OUTPUT_DIR="$DIR/dist"
readonly OUTPUT_DIR

# The templated install script
INPUT_SCRIPT="$DIR/scripts/install.sh"
readonly INPUT_SCRIPT

# Ensure the output dir exists
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/$(basename "$INPUT_SCRIPT")"
readonly OUTPUT_FILE

# Include the git helper
# shellcheck source=/dev/null
source "$DIR/src/git.bash"

# Determine the version
VERSION="$(git::version_or_sha)"

echo "Injecting version $VERSION into $INPUT_SCRIPT..." >&2
sed "s/{{version}}/$VERSION/g" "$INPUT_SCRIPT" >"$OUTPUT_FILE"
chmod +x "$OUTPUT_FILE" >&2
