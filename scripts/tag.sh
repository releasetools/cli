#!/usr/bin/env bash
#
# tag.sh - wrapper script for git::tag_semver
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
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

# Find the semver argument, using the same shape git::release accepts. If there isn't one,
# leave the diagnostic to git::release rather than reporting it twice.
version=""
for arg in "$@"; do
  if [[ "$arg" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    version="$arg"
    break
  fi
done

# Checked before the tag is created, so a stale action.yml costs an edit rather than a
# force-moved tag and a released distributable nobody installs.
if [ -n "$version" ]; then
  "$DIR/scripts/assert-action-version.sh" "$version"
fi

git::release "$@"
