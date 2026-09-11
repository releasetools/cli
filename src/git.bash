#!/usr/bin/env bash
#
# git.bash - git-related helpers for bash
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function git::_internal_check_deps() {
    if ! type git >/dev/null 2>&1; then
        echo "git is not installed." >&2
        return 1
    fi

    if ! type grep >/dev/null 2>&1; then
        echo "grep is not installed." >&2
        return 1
    fi
}

# Checks if the current Git working directory contains uncommitted changes.
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

    # Checked explicitly: as a bare assignment this failed via 'set -e', which kills the
    # caller's shell outright when the library has been sourced, with no explanation.
    if ! git_sha="$(git rev-parse --short HEAD)"; then
        echo "ERROR: could not resolve HEAD; is this a git repository with any commits?" >&2
        return 1
    fi

    echo "${git_sha}$(git::is_dirty)"
}

# Returns a version tag (e.g. 'v#') pointing at the current branch's HEAD.
#
# This function will strip the 'v' prefix from the tag (e.g. 'v1.0.0' is returned as '1.0.0').
# If multiple tags point at HEAD, the highest version is returned; the comparison is
# by version, not lexical, so 'v0.0.10' correctly outranks 'v0.0.9'.
# Returns an empty string if no version tag points at HEAD.
function git::version_tag() {
    local tags
    local tag

    # '--points-at' matches only tags on HEAD itself. '--contains' would also match tags on
    # descendant commits, which made re-running a release for an older tag resolve to the
    # newest one instead.
    #
    # The 'v[0-9]*' pattern is handed to git rather than piped through grep, so that a
    # genuine git failure cannot be mistaken for "HEAD carries no version tag" -- git exits
    # 0 with no output when nothing matches, and non-zero only when it actually failed.
    if ! tags="$(git -c 'versionsort.suffix=-' tag --points-at HEAD --sort='-version:refname' 'v[0-9]*')"; then
        echo "ERROR: could not list git tags" >&2
        return 1
    fi

    # Keep the highest version. Done with parameter expansion rather than 'head -1' so that
    # closing the pipe early cannot surface as a SIGPIPE failure under 'set -o pipefail'.
    tag="${tags%%$'\n'*}"

    echo "${tag#v}"
}

# Returns the latest tag, if associated with the current's branch HEAD,
# or the SHA of the HEAD commit if no tags are found.
function git::version_or_sha() {
    local version
    if ! version="$(git::version_tag)"; then
        return 1
    fi

    if [ -n "$version" ]; then
        # Restore the 'v' prefix that git::version_tag strips. Prefixing before this test
        # (as the previous version did) made the string never empty, so the SHA fallback
        # below was unreachable and an untagged HEAD resolved to the literal 'v'.
        #
        # No dirty marker here, deliberately: this value is baked into install.sh's download
        # URL, so a 'v1.2.3-dirty' would 404 for every consumer. The tag is the release
        # identity; use git::head_sha when you need to know the tree was modified.
        version="v$version"
    else
        # If no version tag was found, use the SHA
        version="$(git::head_sha)"
    fi

    # Fail if neither could be determined
    if [ -z "$version" ]; then
        echo "ERROR: could not determine version or SHA" >&2
        return 1
    fi

    echo "$version"
}

# Returns the most recent known version tag from the remote this repository belongs to.
function git::latest_version() {
    local remote

    # Resolved rather than hardcoded to 'origin'. On a fork that name belongs to the fork,
    # whose tags are not the project's releases.
    if ! remote="$(git::remote)"; then
        return 1
    fi

    git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags "$remote" 'v*.*.*' | tail -1 | cut -d'/' -f3
}

# Creates a release tag for the current HEAD commit.
#
# Requires exactly one argument, a semantic version string (e.g. 'v1.2.3').
# If the version string does not match the semver format, the function
# will terminate with an error.
#
# if '--sign, -s' is specified, the tag(s) will be GPG-signed
# if '--force, -f' is specified, existing tags will be overwritten
# if '--push, -p' is specified, the tag(s) will also be pushed to the remote
# if '--major, -m' is specified, a separate major version tag will be created (e.g., v0 for v0.1.2)
#
# Note: major version tags will always be overwritten if they exists.
#
# Unrecognized options and additional version arguments are rejected rather than ignored:
# a typo such as '--pushh' previously meant "do not push" and still reported success.
#
function git::release() {
    local should_push
    local should_tag_major
    local sign_flag
    local force_flag
    local version
    local major
    local args
    local existing
    local head
    local tag_exists

    # Keep the original arguments for the error message; the loop below consumes "$@"
    args="$*"

    # Determine if the tag should be pushed to remote
    should_push=false
    should_tag_major=false
    sign_flag=""
    force_flag=""
    version=""
    tag_exists=false
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -m | --major)
            should_tag_major=true
            shift
            ;;
        -s | --sign)
            sign_flag="--sign"
            shift
            ;;
        -p | --push)
            should_push=true
            shift
            ;;
        -f | --force)
            force_flag="--force"
            shift
            ;;
        -*)
            # Reject unknown flags rather than ignoring them. A typo such as '--pushh'
            # would otherwise silently mean "do not push" and still exit 0.
            echo "ERROR: unknown option '$1'" >&2
            return 1
            ;;
        *)
            # Identify the semver tag to use
            if [ -n "$version" ]; then
                echo "ERROR: more than one version given: '$version' and '$1'" >&2
                return 1
            fi

            if [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                version="$1"
            else
                echo "ERROR: '$1' is not a valid semver tag" >&2
                return 1
            fi
            shift
            ;;
        esac
    done

    # Check that a valid tag was specified
    if [ -z "$version" ]; then
        echo "ERROR: did not find a valid semver tag in arguments: $args" >&2
        echo "ERROR: semver format is vX.Y.Z, where X, Y, Z are integers" >&2
        return 1
    fi

    # Every git call below is checked. Unchecked, a failing 'git tag' or 'git push' left the
    # trailing 'if' as the function's exit status, so the function reported success after a
    # hard failure in any context that suppresses 'set -e' (such as 'if git::release ...').

    # A run whose push failed leaves the tag behind locally. Creating it again fails even
    # when it already names this commit, and the only flag that clears it is '--force',
    # which is also handed to the push below and would move a published tag. So the retry
    # is answered here instead: reuse a tag that already points at HEAD, refuse one that
    # points anywhere else.
    if [ -z "$force_flag" ]; then
        existing="$(git rev-parse --quiet --verify "refs/tags/$version^{commit}" 2>/dev/null || true)"
        if [ -n "$existing" ]; then
            if ! head="$(git rev-parse HEAD)"; then
                echo "ERROR: could not resolve HEAD" >&2
                return 1
            fi

            if [ "$existing" != "$head" ]; then
                echo "ERROR: tag '$version' already exists and points at $existing, not HEAD ($head)" >&2
                echo "ERROR: delete it or pick another version; releases do not move tags" >&2
                return 1
            fi

            echo "Tag '$version' already points at HEAD; reusing it." >&2
            tag_exists=true
        fi
    fi

    # Create the tag
    if [ "$tag_exists" = false ]; then
        echo "Tagging the HEAD commit with '$version'" >&2
        if ! git tag -a "$version" -m "Release $version" $force_flag $sign_flag; then
            echo "ERROR: failed to tag '$version'" >&2
            return 1
        fi
    fi

    # If --push was specified, push the tag to the remote
    if [ "$should_push" = true ]; then
        if ! git push origin "$version" $force_flag; then
            echo "ERROR: failed to push tag '$version'" >&2
            return 1
        fi
    fi

    # Tag the latest major version
    if [ "$should_tag_major" = true ]; then
        major="${version%%.*}"
        if ! git tag --force -a "$major" -m "Release $version" $sign_flag; then
            echo "ERROR: failed to tag '$major'" >&2
            return 1
        fi

        # If --push was specified, push the tag to the remote
        if [ "$should_push" = true ]; then
            if ! git push --force origin "$major"; then
                echo "ERROR: failed to push tag '$major'" >&2
                return 1
            fi
        fi
    fi
}

# Returns the name of the remote this repository belongs to.
#
# Asked of the repository in decreasing order of how deliberate the answer is. 'origin' is a
# convention rather than an answer: on a fork it names the fork, while the branches and tags
# a release cares about live on the upstream.
#
# 'remote.pushDefault' is deliberately not consulted. It names where commits go, not where
# they come from, and the two differ in exactly the case that makes this question worth
# asking.
#
# Refuses when several remotes exist and nothing says which one, rather than guessing
# 'origin' and resolving a release against the wrong repository.
function git::remote() {
    local candidate branch remotes count

    # The only setting that exists to answer exactly this question.
    candidate="$(git config --get checkout.defaultRemote 2>/dev/null || true)"
    if [ -n "$candidate" ] && git remote get-url "$candidate" >/dev/null 2>&1; then
        echo "$candidate"
        return 0
    fi

    # A detached HEAD has no branch, and '--quiet' makes symbolic-ref fail silently there
    # rather than printing a diagnostic this function has no use for.
    if branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"; then
        candidate="$(git config --get "branch.$branch.remote" 2>/dev/null || true)"
        if [ -n "$candidate" ] && git remote get-url "$candidate" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    fi

    if ! remotes="$(git remote)"; then
        echo "ERROR: could not list remotes" >&2
        return 1
    fi

    # 'grep -c' exits 1 when it counts nothing, which is a count rather than a failure.
    count="$(printf '%s' "$remotes" | grep -c . || true)"

    case "$count" in
    0)
        echo "ERROR: this repository has no remote." >&2
        return 1
        ;;
    1)
        printf '%s\n' "$remotes"
        ;;
    *)
        echo "ERROR: this repository has several remotes and nothing says which one it belongs to:" >&2
        git remote -v | awk '$3 == "(fetch)" { printf "  %s\t%s\n", $1, $2 }' >&2
        echo "ERROR: say which with: git config checkout.defaultRemote <name>" >&2
        return 1
        ;;
    esac
}

# Returns the release tags pointing at HEAD, one per line, highest version first.
#
# '--points-at' rather than '--contains': the latter lists every tag whose history includes
# HEAD, so checking out an older release returns that tag and every later one with it.
#
# Restricted to 'v[0-9]*' because HEAD does not only carry release tags. chart-releaser
# lands a '<chart>-<version>' tag on the very commit being released, and git orders tags by
# refname, which puts the chart's tag first.
#
# Prints nothing and succeeds when HEAD carries no release tag: that is an answer, and the
# pattern is handed to git rather than piped through grep so that a genuine git failure
# cannot be mistaken for it.
function git::tags_at_head() {
    local tags

    if ! tags="$(git -c 'versionsort.suffix=-' tag --points-at HEAD --sort='-version:refname' 'v[0-9]*')"; then
        echo "ERROR: could not list git tags" >&2
        return 1
    fi

    [ -z "$tags" ] || printf '%s\n' "$tags"
}

# Refuses unless a release tag on HEAD names the given version.
#
# The version is passed in rather than read from a project manifest. pyproject.toml,
# package.json, Cargo.toml and Chart.yaml each need a different reader, and every one of
# them would become a dependency this library carries for callers who never use it:
#
#   rt git::assert_tag_version "$(uv version --short)"
#   rt git::assert_tag_version "$(node -p 'require("./package.json").version')"
#
# Accepts '1.2.3' and 'v1.2.3'. Nothing here rewrites a version; it is only verified.
function git::assert_tag_version() {
    local want tags tag

    want="${1-}"
    if [ -z "$want" ]; then
        echo "ERROR: usage: git::assert_tag_version <version>" >&2
        return 1
    fi
    want="${want#v}"

    if ! tags="$(git::tags_at_head)"; then
        return 1
    fi

    if [ -z "$tags" ]; then
        echo "ERROR: no release tag points at HEAD, cannot verify '$want'." >&2
        return 1
    fi

    # A commit can carry more than one tag, so it is enough that one of them matches.
    while IFS='' read -r tag; do
        if [ "${tag#v}" = "$want" ]; then
            echo "Tag matches the version: $want" >&2
            return 0
        fi
    done <<<"$tags"

    echo "ERROR: tag/version mismatch, refusing to continue." >&2
    echo "ERROR:   tag(s) at HEAD: $(tr '\n' ' ' <<<"$tags")" >&2
    echo "ERROR:   version given:  $want" >&2
    return 1
}

# Refuses unless the remote definitely does not carry the given tag.
#
# The remote is the authority. A local clone may carry no tags at all, or stale ones a
# failed push left behind.
#
# Written as an assertion rather than as a predicate on purpose. A predicate invites
# 'git::tag_exists X || release', and '||' fires on every non-zero status, so a network or
# permission failure reads as "the tag is free" and the release goes ahead. Here every
# answer short of a definite "no such ref" is a refusal.
function git::assert_tag_free() {
    local tag remote status

    tag="${1-}"
    if [ -z "$tag" ]; then
        echo "ERROR: usage: git::assert_tag_free <tag>" >&2
        return 1
    fi

    if ! remote="$(git::remote)"; then
        return 1
    fi

    # '|| status=$?' rather than an 'if': the three cases below need the exact status, and
    # this shape also keeps 'set -e' from aborting on the expected non-zero exits.
    status=0
    git ls-remote --exit-code --tags "$remote" "refs/tags/$tag" >/dev/null 2>&1 || status=$?

    case "$status" in
    0)
        echo "ERROR: tag '$tag' already exists on '$remote'." >&2
        echo "ERROR: releases do not move tags; pick the next version." >&2
        return 1
        ;;
    2)
        # git's "no such ref", the one status that means carry on.
        echo "Tag '$tag' is free on '$remote'." >&2
        ;;
    *)
        echo "ERROR: could not ask '$remote' about '$tag' (git exited $status)." >&2
        echo "ERROR: refusing to assume the tag is free." >&2
        return 1
        ;;
    esac
}
