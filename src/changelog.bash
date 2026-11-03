#!/usr/bin/env bash
#
# changelog.bash - reads what was written for a release
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function changelog::_internal_check_deps() {
    if ! type awk >/dev/null 2>&1; then
        echo "awk is not installed." >&2
        return 1
    fi

    if ! type sed >/dev/null 2>&1; then
        echo "sed is not installed." >&2
        return 1
    fi
}

# Prints one version's section of a changelog, heading excluded.
#
# A GitHub release then carries what somebody wrote for this version rather than a list of
# pull request titles. Run it before publishing too: a version with no section is a release
# nobody described, and finding that out after the upload is too late.
#
# Accepts '1.2.3' and 'v1.2.3', and matches '## 1.2.3', '## v1.2.3', '## [1.2.3]' and any
# of those followed by ' - <date>'.
#
# Usage: changelog::section <version> [file]
function changelog::section() {
    local want file section

    want="${1-}"
    if [ -z "$want" ]; then
        echo "ERROR: usage: changelog::section <version> [file]" >&2
        return 1
    fi
    want="${want#v}"

    file="${2:-CHANGELOG.md}"
    if [ ! -f "$file" ]; then
        echo "ERROR: no changelog at '$file'" >&2
        return 1
    fi

    # awk rather than sed, so the heading match is anchored on the whole line: with a
    # substring match, '1.2' opens the section belonging to '1.2.3'.
    if ! section="$(awk -v want="$want" '
        /^## / {
            if (inside) { exit }
            heading = substr($0, 4)
            sub(/ +-.*$/, "", heading)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", heading)
            sub(/^\[/, "", heading)
            sub(/\]$/, "", heading)
            sub(/^v/, "", heading)
            if (heading == want) { inside = 1 }
            next
        }
        inside { print }
    ' "$file")"; then
        echo "ERROR: could not read '$file'" >&2
        return 1
    fi

    # Drop the blank lines the heading boundaries leave behind. Only the leading ones need
    # an explicit pass: command substitution has already eaten the trailing newlines.
    section="$(printf '%s\n' "$section" | sed -e '/./,$!d')"

    if [ -z "$section" ]; then
        echo "ERROR: '$file' has no section for $want." >&2
        echo "ERROR: write one before releasing." >&2
        return 1
    fi

    printf '%s\n' "$section"
}
