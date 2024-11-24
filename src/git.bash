#!/usr/bin/env bash
#
# git.bash - git-related helpers for bash
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function git::internal_check_deps() {
    if ! type git >/dev/null 2>&1; then
        echo "git is not installed." >&2
        return 1
    fi

    if ! type grep >/dev/null 2>&1; then
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
function git::head_sha() {
    local git_sha
    git_sha="$(git rev-parse --short HEAD)"

    echo "${git_sha}$(git::is_dirty)"
}

# Returns a version tag (e.g. 'v#') associated with the current branch's HEAD.
#
# This function will strip the 'v' prefix from the tag (e.g. 'v1.0.0' is returned as '1.0.0').
# If multiple tags are found, the most recent one (naturally sorted) is returned.
# Returns an empty string, if no tags are not found.
function git::version_tag() {
    local tag
    tag="$(git tag --contains HEAD | grep -sE '^v' | sort | tail -1)"
    echo "${tag#v}"
}

# Returns the latest tag, if associated with the current's branch HEAD,
# or the SHA of the HEAD commit if no tags are found.
function git::version_or_sha() {
    local version
    version="v$(git::version_tag)"

    # If no version tag was found, use the SHA
    if [ -z "$version" ]; then
        version="$(git::head_sha)"
    fi

    # Fail if neither could be determined
    if [ -z "$version" ]; then
        echo "ERROR: could not determine version or SHA" >&2
        exit 1
    fi

    echo "$version"
}

# Returns the most recent known version tag from the remote repository (origin)
function git::latest_version() {
    local repo
    repo="$(git config --get remote.origin.url)"
    git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags "$repo" 'v*.*.*' | tail -1 | cut -d'/' -f3
}

# Tags a commit with a semver version creating a signed tag.
#
# Requires one argument, the semver version string (e.g. 'v1.2.3').
# If the version string does not match the semver format, the function
# will terminate with an error.
#
# if '--force' is specified, the semver tag will be overwritten
# if '--push' is specified, the tags will also be pushed to the remote
#
# In all instances and regardless of whether '--force' has been specified,
# this function will also create a major version tag (e.g. 'v1'), overwriting any previously existing such tags.
#
function git::tag_semver() {
    local version

    # Determine if the tag should be pushed to remote
    push_flag=false
    force_flag=""
    version=""
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --push)
            push_flag=true
            shift
            ;;
        --force)
            force_flag="--force"
            shift
            ;;
        *)
            # Identify the semver tag to use
            if [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                version="$1"
            fi
            shift
            ;;
        esac
    done

    # Check that a valid tag was specified
    if [ -z "$version" ]; then
        echo "ERROR: did not find a valid semver tag in arguments: $*" >&2
        echo "ERROR: semver format is vX.Y.Z, where X, Y, Z are integers" >&2
        exit 1
    fi

    # Create the tag
    echo "Tagging the HEAD commit with '$version'" >&2
    git tag -s "$version" -m "Release $version" $force_flag

    # Tag the latest major version
    major="${version%%.*}"
    git tag -a -m "Release $version" "$major" $force_flag

    # If --push was specified, push the tag to the remote
    if [ "$push_flag" = true ]; then
        git push origin "$version" $force_flag
        git push --force origin "$major"
    fi
}
