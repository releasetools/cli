#!/usr/bin/env bash
#
# python.bash - Python-related helpers for bash
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Prints the name of the python interpreter to use, preferring python3.
#
# Probed rather than hardcoded to 'python', which does not exist on a stock macOS or on
# most current Linux distributions. Assuming it did is what made 'base::check_deps' fail
# for anyone who installed via Homebrew.
function python::_interpreter() {
    local candidate

    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

# Prints a python snippet that defines load(path) for reading a TOML file.
#
# 'tomllib' is in the standard library from python 3.11, so no third-party package is
# needed on any current interpreter. The 'toml' fallback keeps older ones working without
# making it a requirement. Both the dependency check and the actual read use this, so the
# check cannot pass while the read fails.
function python::_toml_loader() {
    cat <<'PYTHON'
import sys

try:
    import tomllib

    def load(path):
        with open(path, "rb") as handle:
            return tomllib.load(handle)
except ImportError:
    import toml

    def load(path):
        return toml.load(path)
PYTHON
}

# Test to ensure that all required utilities are installed.
function python::_internal_check_deps() {
    local py

    if ! py="$(python::_interpreter)"; then
        echo "python is not installed (looked for 'python3' and 'python')." >&2
        return 1
    fi

    if ! "$py" -c "$(python::_toml_loader)" >/dev/null 2>&1; then
        echo "Cannot read TOML with $(command -v "$py")." >&2
        echo "Use python 3.11 or newer, which bundles 'tomllib', or install the" >&2
        echo "'toml' package for this interpreter." >&2
        return 1
    fi
}

# Extracts the project name as configured in 'pyproject.toml'
function python::project_name() {
    # Defaulted: the library runs under 'set -u', so a bare "$1" made calling this with no
    # arguments die on an unbound variable instead of printing the message below.
    local dir="${1-}"
    local py

    # error out if dir is not set
    if [[ ! -d "$dir" ]]; then
        echo "You must provide a directory as argument." >&2
        return 1
    fi

    # if pyproject.toml doesn't exist, error out
    if [[ ! -f "$dir/pyproject.toml" ]]; then
        echo "Directory '$dir' does not contain a 'pyproject.toml'." >&2
        return 1
    fi

    if ! py="$(python::_interpreter)"; then
        echo "python is not installed (looked for 'python3' and 'python')." >&2
        return 1
    fi

    # The path is passed as an argument rather than interpolated into the source, so a
    # directory containing a quote character cannot break or inject into the snippet.
    "$py" -c "$(python::_toml_loader)
print(load(sys.argv[1])[\"project\"][\"name\"])" "$dir/pyproject.toml"
}
