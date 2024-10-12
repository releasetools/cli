#!/usr/bin/env bash

# Set the base directory as the parent of the current script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd -P)"
readonly DIR

# Include the git helper
# shellcheck source=/dev/null
source "$DIR/src/git.bash"

git::tag_semver "$@"
