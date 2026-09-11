#!/usr/bin/env bash
#
# net.bash - HTTP helpers for release checks
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function net::_internal_check_deps() {
    if ! type curl >/dev/null 2>&1; then
        echo "curl is not installed." >&2
        return 1
    fi
}

# The User-Agent every request here carries.
#
# Not decoration. crates.io answers 403 to a request without one, and a check that reads
# "already published" out of a blocked request refuses a release that should go ahead.
function net::_user_agent() {
    echo "releasetools-cli/{{version}}"
}

# Returns the HTTP status code for a URL.
#
# No '--fail': a 404 is the answer this is asked for, not an error. A transport failure is
# an error, and it is kept distinct, because curl reports one as the code '000' and
# comparing that against 404 turns an outage into "safe to publish".
#
# Usage: net::status <url>
function net::status() {
    local url code status

    url="${1-}"
    if [ -z "$url" ]; then
        echo "ERROR: usage: net::status <url>" >&2
        return 1
    fi

    status=0
    code="$(curl -sSL --max-time 30 -A "$(net::_user_agent)" -o /dev/null -w '%{http_code}' -- "$url")" || status=$?

    if [ "$status" -ne 0 ] || [ -z "$code" ] || [ "$code" = "000" ]; then
        echo "ERROR: could not reach $url (curl exited $status)" >&2
        return 1
    fi

    echo "$code"
}

# Waits until a URL answers 200, backing off exponentially.
#
# This exists for one reason: an index or a CDN takes time to serve what it has just
# accepted. A short fixed wait fails releases that published correctly, so the delays grow
# instead. Six attempts at a 15 second base is 15, 30, 60, 120 and 240 seconds, covering
# roughly 7.75 minutes.
#
# Usage: net::await_url <url> [--attempts N] [--base SECONDS]
function net::await_url() {
    local url attempts base count delay code

    url=""
    attempts=6
    base=15
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --attempts)
            attempts="${2-}"
            shift 2
            ;;
        --base)
            base="${2-}"
            shift 2
            ;;
        -*)
            echo "ERROR: unknown option '$1'" >&2
            return 1
            ;;
        *)
            if [ -n "$url" ]; then
                echo "ERROR: more than one URL given: '$url' and '$1'" >&2
                return 1
            fi
            url="$1"
            shift
            ;;
        esac
    done

    if [ -z "$url" ]; then
        echo "ERROR: usage: net::await_url <url> [--attempts N] [--base SECONDS]" >&2
        return 1
    fi

    if [[ ! "$attempts" =~ ^[0-9]+$ ]] || [ "$attempts" -lt 1 ]; then
        echo "ERROR: --attempts must be a positive integer, got '$attempts'" >&2
        return 1
    fi

    if [[ ! "$base" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --base must be an integer number of seconds, got '$base'" >&2
        return 1
    fi

    count=0
    delay="$base"
    while [ "$count" -lt "$attempts" ]; do
        count=$((count + 1))

        # A transport failure is retried like a wrong status: the thing being waited for is
        # often a name that does not resolve yet.
        code="$(net::status "$url" 2>/dev/null || true)"
        if [ "$code" = "200" ]; then
            echo "$url is serving (attempt $count)." >&2
            return 0
        fi

        if [ "$count" -ge "$attempts" ]; then
            break
        fi

        echo "waiting ${delay}s for $url (attempt $count/$attempts, last status ${code:-unreachable})..." >&2
        sleep "$delay"
        delay=$((delay * 2))
    done

    echo "ERROR: $url did not serve after $attempts attempts (last status ${code:-unreachable})." >&2
    return 1
}
