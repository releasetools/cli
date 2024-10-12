#!/usr/bin/env bash
#
# git.bash - git-related helpers for bash
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Usage:
#   Source this module directly, or in your .bashrc or .bash_profile
#

# Test to ensure that all required utilities are installed.
function git::check_deps() {
    if ! type git > /dev/null 2>&1; then
        echo "git is not installed." >&2
        return 1
    fi

    if ! type grep > /dev/null 2>&1; then
        echo "grep is not installed." >&2
        return 1
    fi
}

# Checks if the current Git working directory contains uncommited changes.
#
# Prints nothing if the working directory is clean, '-dirty' otherwise.
function git::is_dirty() {
    if [ -n "$(git status --porcelain)" ]; then
        echo "-dirty"
    else
        echo ""
    fi
}

# Get the current branch HEAD's SHA.
#
# Returns the SHA as a string and appends '-dirty' if the
# working directory contains uncommitted changes.
git::head_sha() {
    local git_sha
    git_sha="$(git rev-parse --short HEAD)"

    echo "${git_sha}$(is_dirty)"
}


# Returns a version tag (e.g. 'v#') associated with the current branch's HEAD.
#
# This function will strip the 'v' prefix from the tag (e.g. 'v1.0.0' is returned as '1.0.0').
# If multiple tags are found, the most recent one (naturally sorted) is returned.
# Returns an empty string, if no tags are not found.
git::get_version_tag() {
    local tag
    tag="$(git tag --contains HEAD | grep -sE '^v' | sort | tail -1)"
    echo "${tag#v}"
}
