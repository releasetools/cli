#!/usr/bin/env bash
#
# generate-dist.sh - generates the dist package by concatenating all the scripts in src/
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

# Output directory
OUTPUT_DIR="$DIR/dist"
readonly OUTPUT_DIR

# Ensure the output dir exists
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

# Name of the output file
OUTPUT_FILE="$OUTPUT_DIR/releasetools.bash"
readonly OUTPUT_FILE

# Ensure all the expected directories exist
for dir in "$DIR/src" "$DIR/scripts"; do
  if [ ! -d "$dir" ]; then
    echo "Something is wrong. Directory '$dir' does not exist." >&2
    exit 1
  fi
done

# Include the git helper
# shellcheck source=/dev/null
source "$DIR/src/git.bash"

# Determine the version
VERSION="$(git::version_or_sha)"
readonly VERSION

# Parses a module, applying any required post-processing
function _parse_module() {
  # Do not include the shebang line, and replace the version placeholder.
  #
  # The shebang deletion is anchored to line 1: unanchored, it also deleted matching lines
  # from the middle of a module (inside a heredoc, for instance), silently.
  #
  # The version is escaped for use as a sed replacement, so a version containing '/' or '&'
  # cannot corrupt the substitution.
  local escaped_version
  escaped_version="$(printf '%s' "$VERSION" | sed -e 's/[\/&\\]/\\&/g')"

  sed '1{/^#!\/usr\/bin\/env bash$/d;}' "$1" | sed "s/{{version}}/$escaped_version/g"
}

echo "Concatenating modules into '$OUTPUT_FILE', version '$VERSION'." >&2

# Start the output file with a shebang line and optional header
{
  echo "#!/usr/bin/env bash"
  echo ""
  echo "# Release tools, built for bash"
  echo "# Version: $VERSION"
  echo "# <https://github.com/releasetools/cli>"
  echo ""
} >"$OUTPUT_FILE"

# Loop through each .bash file in the module directory
modules=()
for module in "$DIR"/src/*.bash; do
  name="$(basename "$module")"
  # store each module name
  modules+=("${name%.bash}")

  # Check if the file exists and is readable
  if [ -r "$module" ]; then
    echo "Adding $name" >&2
    {
      echo ""
      echo "### Start of $name"
      echo ""
      # Do not include the shebang line
      # And replace the version placeholder
      _parse_module "$module"
      echo ""
      echo "### End of $name"
      echo ""
    } >>"$OUTPUT_FILE"

    # Append the module content to the output file
  else
    echo "Cannot read module '$module'. Skipping." >&2
  fi
done

echo "Adding base::check_deps()" >&2
{
  echo ""
  echo "# Ensure all dependencies are installed"
  echo "#"
  echo "# Every namespace is checked, so a single failure does not hide the rest, and the"
  echo "# accumulated status is returned. The previous form ended each line with a subshell"
  echo "# ('|| ( ... && exit 1 )'), whose 'exit' could only leave the subshell -- so the"
  echo "# function reported 'Ok.' and returned 0 wherever 'set -e' was suppressed."
  echo "function base::check_deps() {"
  echo "  local rc=0"
  for m in "${modules[@]}"; do
    echo "  $m::_internal_check_deps || { echo \"ERROR: $m::_internal_check_deps\" >&2; rc=1; }"
  done
  echo "  if [ \"\$rc\" -ne 0 ]; then"
  echo "    return \"\$rc\""
  echo "  fi"
  echo "  echo \"Ok.\" >&2"
  echo "}"
  echo ""
} >>"$OUTPUT_FILE"

echo "Adding main.sh" >&2
{
  echo ""
  # Include the main function
  _parse_module "$DIR/scripts/main.sh"
} >>"$OUTPUT_FILE"

echo >&2
echo "All modules have been concatenated into '$OUTPUT_FILE'." >&2
chmod +x "$OUTPUT_FILE"

# Generate the checksum
CHECKSUM_FILE="$OUTPUT_FILE.sha256"
pushd "$(dirname "$OUTPUT_FILE")" >/dev/null || exit 1
shasum -a 256 "$(basename "$OUTPUT_FILE")" >"$CHECKSUM_FILE"
echo "Checksum stored in '$CHECKSUM_FILE'." >&2
popd >/dev/null || exit 1
