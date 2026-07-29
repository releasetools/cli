#!/usr/bin/env bash
#
# assert-action-version.sh - checks that action.yml's default version matches a release tag
#
# 'action.yml' pins the version that a consumer writing 'uses: releasetools/cli@v0'
# installs, because that input has no other source. 'git::release --major' force-moves
# the v0 tag onto every release, so if the default is not bumped in the commit being
# tagged, @v0 keeps serving the previous release -- and the test-default job in
# test-release.yaml passes while exercising the old distributable.
#
# Nothing else notices, which is why this is a check rather than a comment.
#
# Usage: assert-action-version.sh vX.Y.Z
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

ACTION_FILE="$DIR/action.yml"
readonly ACTION_FILE

EXPECTED="${1-}"
readonly EXPECTED

if [ -z "$EXPECTED" ]; then
  echo "ERROR: no version given." >&2
  echo "Usage: $(basename "$0") vX.Y.Z" >&2
  exit 1
fi

if [ ! -f "$ACTION_FILE" ]; then
  echo "ERROR: '$ACTION_FILE' does not exist." >&2
  exit 1
fi

# Read the first 'default: "v..."' line. Restricted to a v-prefixed semver value so a
# future unrelated 'default:' key cannot be picked up by accident.
DECLARED="$(sed -n 's/^[[:space:]]*default:[[:space:]]*"\(v[0-9][^"]*\)".*/\1/p' "$ACTION_FILE" | head -1)"
readonly DECLARED

# An empty result means the file no longer has the shape this check assumes. Treating
# that as a pass would silently disable the check, which is the failure it exists to stop.
if [ -z "$DECLARED" ]; then
  echo "ERROR: could not find a 'default: \"vX.Y.Z\"' line in '$ACTION_FILE'." >&2
  echo "ERROR: if the input was renamed or restructured, update this check too." >&2
  exit 1
fi

if [ "$DECLARED" != "$EXPECTED" ]; then
  echo "ERROR: action.yml declares version '$DECLARED', but the release is '$EXPECTED'." >&2
  echo "ERROR: bump the 'default:' value in action.yml and commit it before tagging," >&2
  echo "ERROR: or every 'uses: releasetools/cli@v0' consumer will keep installing" >&2
  echo "ERROR: '$DECLARED' after the v0 tag moves." >&2
  exit 1
fi

echo "action.yml default version matches the release ($EXPECTED)." >&2
