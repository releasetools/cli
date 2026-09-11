#!/usr/bin/env bash
#
# github.bash - GitHub-related helpers for bash
#
# Every function here shells out to the GitHub CLI, which resolves the repository the same
# way it does everywhere else: from 'GH_REPO' when set, otherwise from the checkout's
# remote. 'GITHUB_REPOSITORY' is not part of that, so a workflow sets 'GH_REPO' alongside
# 'GH_TOKEN':
#
#   env:
#     GH_TOKEN: ${{ github.token }}
#     GH_REPO: ${{ github.repository }}
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
#
# 'gh' is checked here rather than declared as a package dependency. Homebrew has no
# construct for a dependency only one namespace needs, and the two it does have install it
# for everybody, so the check lives where the requirement does.
function github::_internal_check_deps() {
    if ! type gh >/dev/null 2>&1; then
        echo "The GitHub CLI (gh) is not installed; the github:: namespace needs it." >&2
        return 1
    fi
}

# Refuses unless the given branch already took the commit, asked over the API.
#
# The answer needs no local history at all, which is what makes this usable where
# git::assert_on_branch is not: a shallow clone, or a repository too large to fetch in
# full. It needs 'GH_TOKEN' and a GitHub remote in exchange.
#
# 'ahead_by' is the whole answer. A commit the branch already has is 'behind' or
# 'identical' with nothing ahead; one the branch never took is 'ahead' or 'diverged'.
#
# Usage: github::assert_on_branch [branch] [commit]
function github::assert_on_branch() {
    local branch commit ahead

    branch="${1:-main}"
    commit="${2-}"
    if [ -z "$commit" ]; then
        if ! commit="$(git rev-parse HEAD)"; then
            echo "ERROR: no commit given and HEAD could not be resolved" >&2
            return 1
        fi
    fi

    if ! ahead="$(gh api "repos/{owner}/{repo}/compare/$branch...$commit" --jq '.ahead_by')"; then
        echo "ERROR: could not compare '$commit' against '$branch'." >&2
        echo "ERROR: set GH_REPO when running outside a checkout, and GH_TOKEN to authenticate." >&2
        return 1
    fi

    if [ "$ahead" != "0" ]; then
        echo "ERROR: '$commit' is not on '$branch' ($ahead commit(s) ahead of it)." >&2
        echo "ERROR: merge it first, then tag the commit on '$branch'." >&2
        return 1
    fi

    echo "$commit is on $branch." >&2
}

# Waits for one workflow's run on a commit, and fails if that run failed.
#
# Asks for a named workflow's runs rather than for the commit's check runs. A publishing
# workflow writes check runs onto the very commit it is releasing, so "wait until every
# check is complete" would be waiting for itself.
#
# Usage: github::await_workflow <commit-sha> <workflow.yml> [--timeout SECONDS]
function github::await_workflow() {
    local sha workflow timeout deadline state now

    sha=""
    workflow=""
    timeout=1800
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --timeout)
            timeout="${2-}"
            shift 2
            ;;
        -*)
            echo "ERROR: unknown option '$1'" >&2
            return 1
            ;;
        *)
            if [ -z "$sha" ]; then
                sha="$1"
            elif [ -z "$workflow" ]; then
                workflow="$1"
            else
                echo "ERROR: unexpected argument '$1'" >&2
                return 1
            fi
            shift
            ;;
        esac
    done

    if [ -z "$sha" ] || [ -z "$workflow" ]; then
        echo "ERROR: usage: github::await_workflow <commit-sha> <workflow.yml> [--timeout SECONDS]" >&2
        return 1
    fi

    if [[ ! "$timeout" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --timeout must be an integer number of seconds, got '$timeout'" >&2
        return 1
    fi

    deadline=$(($(date +%s) + timeout))
    while true; do
        if ! state="$(gh run list --commit "$sha" --workflow "$workflow" \
            --json status,conclusion --jq '.[0] | "\(.status) \(.conclusion // "-")"')"; then
            echo "ERROR: could not list runs of '$workflow' for $sha." >&2
            echo "ERROR: set GH_REPO when running outside a checkout, and GH_TOKEN to authenticate." >&2
            return 1
        fi

        case "$state" in
        "completed success")
            echo "$workflow passed on $sha" >&2
            return 0
            ;;
        "completed "*)
            echo "ERROR: $workflow on $sha: ${state#completed }. Refusing to continue." >&2
            return 1
            ;;
        "")
            # No run at all yet. A commit that reached the branch has one; a tag pushed
            # seconds after a merge can arrive before it.
            echo "waiting for $workflow to start on $sha..." >&2
            ;;
        *)
            echo "waiting for $workflow on $sha: $state" >&2
            ;;
        esac

        now="$(date +%s)"
        if [ "$now" -ge "$deadline" ]; then
            echo "ERROR: gave up waiting for $workflow on $sha after ${timeout}s." >&2
            return 1
        fi
        sleep 15
    done
}

# Refuses when a release already exists for the tag and carries assets.
#
# A release with no assets is a previous run that failed partway, and there is nothing
# published to protect, so it is allowed through with a notice. One with assets is a
# release somebody may already have downloaded, and tag protection means it cannot be
# moved: the way forward is the next version.
#
# Usage: github::assert_release_absent <tag>
function github::assert_release_absent() {
    local tag output status

    tag="${1-}"
    if [ -z "$tag" ]; then
        echo "ERROR: usage: github::assert_release_absent <tag>" >&2
        return 1
    fi

    status=0
    output="$(gh api "repos/{owner}/{repo}/releases/tags/$tag" --jq '.assets | length' 2>&1)" || status=$?

    if [ "$status" -ne 0 ]; then
        # A 404 is the answer. Anything else is a failure to get one, and treating the two
        # alike would let an expired token report every tag as unreleased.
        case "$output" in
        *"HTTP 404"*)
            echo "No release exists for '$tag'." >&2
            return 0
            ;;
        *)
            echo "ERROR: could not ask about the release for '$tag':" >&2
            echo "$output" >&2
            return 1
            ;;
        esac
    fi

    if [ "$output" = "0" ]; then
        echo "Release '$tag' exists with no assets, likely a prior run that failed; continuing." >&2
        return 0
    fi

    echo "ERROR: release '$tag' already exists with $output asset(s)." >&2
    echo "ERROR: a published release cannot be replaced; ship the next version instead." >&2
    return 1
}

# Sends a repository_dispatch event to another repository.
#
# GITHUB_TOKEN is scoped to the repository running the workflow and cannot dispatch across
# repositories, so the caller supplies a token that can, through GH_TOKEN.
#
# Usage: github::dispatch <owner/repo> <event-type> [key=value ...]
function github::dispatch() {
    local repo event pair
    local -a args

    repo="${1-}"
    event="${2-}"
    if [ -z "$repo" ] || [ -z "$event" ]; then
        echo "ERROR: usage: github::dispatch <owner/repo> <event-type> [key=value ...]" >&2
        return 1
    fi
    shift 2

    # Seeded rather than built up from empty, so the expansion below is never an unset
    # array under 'set -u'.
    args=(--method POST "repos/$repo/dispatches" -f "event_type=$event")

    for pair in "$@"; do
        if [[ "$pair" != *=* ]]; then
            echo "ERROR: payload entries are 'key=value', got '$pair'" >&2
            return 1
        fi
        args+=(-f "client_payload[${pair%%=*}]=${pair#*=}")
    done

    if ! gh api "${args[@]}" >/dev/null; then
        echo "ERROR: could not dispatch '$event' to '$repo'." >&2
        return 1
    fi

    echo "Dispatched '$event' to '$repo'." >&2
}
