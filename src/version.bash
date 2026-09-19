#!/usr/bin/env bash
#
# version.bash - sets a project's version, with the command the project declares
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
#
# Nothing new: the command a project declares brings its own, and git is git::'s.
function version::_internal_check_deps() {
    return 0
}

# Runs the command that sets a project's version, then proves it took.
#
# Every ecosystem ships one: 'uv version 1.2.3', 'npm version 1.2.3 --no-git-tag-version',
# 'cargo set-version 1.2.3'. So nothing here parses or rewrites a manifest, which is the
# part that would need a different implementation per ecosystem and would be wrong in a
# new one. The project says how, in the 'bump' key of .releasetools.yaml, and whatever
# coordinates the release passes it here.
#
# The command is the repository's own, from a file in the repository, and it is run as
# written. That is the same trust a Makefile has.
#
# Running it twice is safe: a manifest that already declares the version is left alone.
#
# Usage: version::bump <version> --command <template> [--manifest <file>] [--dir <path>]
function version::bump() {
    local version command manifest dir rendered

    version="${1-}"
    shift || true
    if [ -z "$version" ]; then
        echo "ERROR: usage: version::bump <version> --command <template> [--manifest <file>] [--dir <path>]" >&2
        return 1
    fi
    version="${version#v}"

    command=""
    manifest=""
    dir="."
    while [ $# -gt 0 ]; do
        case "$1" in
        --command)
            command="${2-}"
            shift 2 || return 1
            ;;
        --manifest)
            manifest="${2-}"
            shift 2 || return 1
            ;;
        --dir)
            dir="${2-}"
            shift 2 || return 1
            ;;
        *)
            echo "ERROR: unknown argument '$1'" >&2
            return 1
            ;;
        esac
    done

    if [ -z "$command" ]; then
        echo "ERROR: --command is the command that sets the version, for example" >&2
        echo "ERROR:   --command 'uv version {version}'" >&2
        return 1
    fi

    case "$command" in
    *"{version}"*) ;;
    *)
        echo "ERROR: --command must say where the version goes, as {version}." >&2
        return 1
        ;;
    esac

    if [ ! -d "$dir" ]; then
        echo "ERROR: no directory at '$dir'" >&2
        return 1
    fi

    # Already there, so there is nothing to run and nothing to undo.
    if [ -n "$manifest" ] && [ -f "$dir/$manifest" ] &&
        grep -qF "$version" "$dir/$manifest"; then
        echo "$manifest already declares $version."
        return 0
    fi

    rendered="${command//\{version\}/$version}"
    echo "Running: $rendered"
    if ! (cd "$dir" && eval "$rendered"); then
        echo "ERROR: '$rendered' failed. Nothing here has changed the manifest." >&2
        return 1
    fi

    # The command ran; whether it did what it says is a separate question. A manifest that
    # still does not carry the version means the wrong command, the wrong directory, or a
    # tool that writes somewhere else, and finding that out now beats finding it out from
    # a published release.
    if [ -n "$manifest" ]; then
        if [ ! -f "$dir/$manifest" ]; then
            echo "ERROR: no manifest at '$dir/$manifest' after running the command." >&2
            return 1
        fi
        if ! grep -qF "$version" "$dir/$manifest"; then
            echo "ERROR: '$dir/$manifest' still does not declare $version." >&2
            echo "ERROR: the command ran and set something else, or set it elsewhere." >&2
            return 1
        fi
    fi

    git -C "$dir" status --porcelain -- . || true
}
