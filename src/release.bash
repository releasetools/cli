#!/usr/bin/env bash
#
# release.bash - everything that has to be true before a release starts
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
#
# Nothing new: this namespace composes git:: and net::, and each checks its own.
function release::_internal_check_deps() {
    return 0
}

# Returns 0 when the first version is strictly after the second, 1 when it is not, and 2
# when either is not a version.
#
# Compared component by component as integers rather than as strings, so 0.10.0 is after
# 0.9.0. A non-numeric component is refused rather than read as 0.
#
# A prerelease sorts before the release it leads to, as semver says and as
# 'versionsort.suffix=-' already makes git's own tag sort do. Without that, a project that
# cuts release candidates could never run these checks for the version following one:
# 'v2.0.0-rc1' is then the newest tag the remote carries, and 2.0.0 could not be compared
# against it at all. Two prereleases of the same version are compared as strings, which is
# right for 'rc1' against 'rc2' and an approximation past that.
function release::_is_after() {
    local a b i want_core want_pre have_core have_pre
    local -a want have

    want_core="${1#v}"
    want_pre=""
    case "$want_core" in
    *-*)
        want_pre="${want_core#*-}"
        want_core="${want_core%%-*}"
        ;;
    esac

    have_core="${2#v}"
    have_pre=""
    case "$have_core" in
    *-*)
        have_pre="${have_core#*-}"
        have_core="${have_core%%-*}"
        ;;
    esac

    IFS='.' read -r -a want <<<"$want_core"
    IFS='.' read -r -a have <<<"$have_core"

    for i in 0 1 2; do
        a="${want[$i]:-0}"
        b="${have[$i]:-0}"

        if [[ ! "$a" =~ ^[0-9]+$ ]] || [[ ! "$b" =~ ^[0-9]+$ ]]; then
            echo "ERROR: cannot compare '$1' with '$2' as versions" >&2
            return 2
        fi

        if [ "$a" -gt "$b" ]; then
            return 0
        fi

        if [ "$a" -lt "$b" ]; then
            return 1
        fi
    done

    # Same core version. A release is after its own prereleases, a prerelease is not after
    # the release it leads to, and nothing is after itself.
    if [ -z "$want_pre" ] && [ -n "$have_pre" ]; then
        return 0
    fi

    if [ -n "$want_pre" ] && [ -n "$have_pre" ] && [[ "$want_pre" > "$have_pre" ]]; then
        return 0
    fi

    return 1
}

# Refuses a release that cannot succeed, while every reason is still free to fix.
#
# The version is passed in rather than read from a project manifest, so this needs no TOML,
# JSON or YAML parser:
#
#   rt release::prechecks "$(uv version --short)" \
#       --branch main \
#       --check-registry-url "https://pypi.org/pypi/my-package/1.2.3/json"
#
# Checked in order, cheapest first:
#
#   1. the version is x.y.z
#   2. the working tree is clean
#   3. the tag is free on the remote
#   4. the version is after the newest release tag the remote carries
#   5. HEAD is on the branch, when --branch is given
#   6. the registry answers 404 for it, when --check-registry-url is given
#
# Step 4 asks the remote's tags rather than a version committed to a branch. The two
# disagree only when a bump has been merged and not yet tagged, which is the normal state
# in a flow where the tag follows the merge, and there the tags are the ones that are right.
#
# Usage: release::prechecks <version> [--branch <name>] [--check-registry-url <url>]
function release::prechecks() {
    local version branch registry_url latest code status

    version=""
    branch=""
    registry_url=""
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --branch)
            # Checked before shifting: 'shift 2' with one argument left returns non-zero,
            # and under 'set -e' that aborts before the validation below can say why.
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --branch needs a value" >&2
                return 1
            fi
            branch="$2"
            shift 2
            ;;
        --check-registry-url)
            # Checked before shifting: 'shift 2' with one argument left returns non-zero,
            # and under 'set -e' that aborts before the validation below can say why.
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --check-registry-url needs a value" >&2
                return 1
            fi
            registry_url="$2"
            shift 2
            ;;
        -*)
            echo "ERROR: unknown option '$1'" >&2
            return 1
            ;;
        *)
            if [ -n "$version" ]; then
                echo "ERROR: more than one version given: '$version' and '$1'" >&2
                return 1
            fi
            version="$1"
            shift
            ;;
        esac
    done

    if [ -z "$version" ]; then
        echo "ERROR: usage: release::prechecks <version> [--branch <name>] [--check-registry-url <url>]" >&2
        return 1
    fi
    version="${version#v}"

    # 1. Shape. A release workflow triggers on a tag pattern, so a version it cannot match
    #    would merge and then publish nothing at all.
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "ERROR: '$version' is not x.y.z" >&2
        return 1
    fi

    # 2. A clean tree, because a release branch cut from the remote carries uncommitted work
    #    onto it, and a version read from the working copy may not be the one being tagged.
    if git::is_dirty; then
        git status --porcelain >&2
        echo "ERROR: the working tree is dirty; commit or stash first." >&2
        return 1
    fi

    # 3. The tag has to be free, asked of the remote.
    if ! git::assert_tag_free "v$version"; then
        return 1
    fi

    # 4. Forward only, against the newest release tag the remote carries. A repository that
    #    has never released has none, which is read as 0.0.0.
    status=0
    latest="$(git::latest_version 2>/dev/null)" || status=$?
    if [ "$status" -ne 0 ] || [ -z "$latest" ]; then
        # git::latest_version fails both when the remote carries no release tag and when it
        # could not be asked, without saying which. Step 3 asked that same remote a moment
        # ago and got an answer, so only the first is left by the time this runs. Reordering
        # these checks would make that untrue.
        latest="0.0.0"
    fi

    status=0
    release::_is_after "$version" "$latest" || status=$?
    case "$status" in
    0) ;;
    1)
        echo "ERROR: the newest release is ${latest#v}; $version is not after it." >&2
        return 1
        ;;
    *)
        return 1
        ;;
    esac

    # 5. On the branch, when asked. Releasing from a commit the branch never took publishes
    #    something no review ever saw.
    if [ -n "$branch" ]; then
        if ! git::assert_on_branch "$branch"; then
            return 1
        fi
    fi

    # 6. And the registry, because an index rejects a duplicate at the very end of an upload
    #    run, after everything else has already happened, and a published version cannot be
    #    replaced.
    if [ -n "$registry_url" ]; then
        if ! code="$(net::status "$registry_url")"; then
            return 1
        fi

        case "$code" in
        404)
            echo "The registry does not carry $version yet." >&2
            ;;
        200)
            echo "ERROR: the registry already has $version:" >&2
            echo "ERROR:   $registry_url" >&2
            echo "ERROR: a published version cannot be replaced; pick the next one." >&2
            return 1
            ;;
        *)
            echo "ERROR: the registry answered $code for $registry_url." >&2
            echo "ERROR: refusing to assume $version is unpublished." >&2
            return 1
            ;;
        esac
    fi

    echo "${latest#v} -> $version, and v$version is free." >&2
}
