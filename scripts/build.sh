#!/usr/bin/env bash

# Set the base directory as the parent of the current script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd -P)"
readonly DIR

# Name of the output file
OUTPUT_FILE="$DIR/dist/all.bash"
readonly OUTPUT_FILE

# Ensure the output file can be generated
mkdir -p "$DIR/dist/"

# Directory where your modules are stored
MODULE_DIR="$DIR/src"
readonly MODULE_DIR

# Ensure the module directory exists
if [ ! -d "$MODULE_DIR" ]; then
  echo "Module directory '$MODULE_DIR' does not exist." >&2
  exit 1
fi

echo "Concatenated modules into '$OUTPUT_FILE'." >&2

# Start the output file with a shebang line and optional header
{
  echo "#!/usr/bin/env bash"
  echo ""
  echo "# All bash release tools"
  echo ""
} >"$OUTPUT_FILE"

# Loop through each .bash file in the module directory
for module in "$MODULE_DIR"/*.bash; do
  name="$(basename "$module")"

  # Check if the file exists and is readable
  if [ -r "$module" ]; then
    echo "Adding $name" >&2
    {
      echo ""
      echo "### Start of $name"
      echo ""
      # Do not include the shebang line
      sed '/^#!\/usr\/bin\/env bash/d' "$module"
      echo ""
      echo "### End of $name"
      echo ""
    } >>"$OUTPUT_FILE"

    # Append the module content to the output file
  else
    echo "Cannot read module '$module'. Skipping." >&2
  fi
done

echo
echo "All modules have been concatenated into '$OUTPUT_FILE'." >&2

CHECKSUM_FILE="$OUTPUT_FILE.sha256"
pushd "$(dirname "$OUTPUT_FILE")" >&2 >/dev/null || exit 1
sha256sum "$(basename "$OUTPUT_FILE")" >"$CHECKSUM_FILE"
echo "Checksum stored in '$CHECKSUM_FILE'." >&2
popd >&2 >/dev/null || exit 1
