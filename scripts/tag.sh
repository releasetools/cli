#!/usr/bin/env bash
#
# tag.sh - wrapper script for git::tag_semver
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

# Include the git helper
# shellcheck source=/dev/null
source "$DIR/src/git.bash"

git::release "$@"
