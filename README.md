# Release tools for bash workflows

This toolkit represents a collection of bash scripts for various purposes.

> Any and all contributions are welcome; just open a PR.

## Quickstart

1\. Install the tools

```shell
# curl
bash <(curl -sSL "https://github.com/releasetools/cli/releases/latest/download/install.sh")

# or wget
bash <(wget -q -O- "https://github.com/releasetools/cli/releases/latest/download/install.sh")
```

> These URLs always resolve to the most recent release. To install a specific version,
> replace `latest/download` with `download/vX.Y.Z`.

Or alternatively, with `brew`:

```shell
brew tap releasetools/tap
brew install releasetools-cli
```

The tools will by default be installed to `~/.local/share/releasetools/cli/VERSION/`, and two symlinks are created in `~/.local/bin`: `releasetools` and the shorter `rt`. Both run the same script, and `brew` installs the same pair.

2\. Utilize the _releasetools_ library

```shell
# With ~/.local/bin in your PATH:
export PATH=~/.local/bin:"$PATH"

# You can run commands, e.g.:
releasetools version
# vX.Y.Z

# 'rt' is the same script under a shorter name
rt version
# vX.Y.Z

# Optionally, check that all dependencies for all modules are correctly installed
releasetools base::check_deps
# Ok.

# You can also check the install location
releasetools base::install_location
# /Users/user/.local/share/releasetools/cli/vX.Y.Z/releasetools.bash
```

### Customizations

Several customizations can be applied prior to installation:

1\. The location where the tools will be installed:

```shell
export RELEASETOOLS_INSTALL_DIR="$HOME/.local/share"
# proceed with the installation steps outlined above
```

2\. The path where the binary is symlinked:

```shell
export RELEASETOOLS_BINARY_DIR="$HOME/.local/bin"
# proceed with the installation steps outlined above
```

## Release checks

Four assertions that a release pipeline runs before it publishes anything. Each one prints
its reasoning on stderr and returns non-zero when it cannot prove what it is asked to
prove, so a doubtful answer stops a release rather than passing it.

```shell
# The tag on HEAD names the version you think you are releasing.
# The version is passed in, so this reads no project manifest and needs no TOML, JSON or
# YAML parser of its own.
rt git::assert_tag_version "$(uv version --short)"

# The remote does not already carry the tag. Asked of the remote, because a local clone
# may have no tags at all. A failure to ask is a refusal, never a "yes".
rt git::assert_tag_free "v1.2.3"
```

```shell
# The release tags pointing at HEAD, highest first, or nothing when there are none.
rt git::tags_at_head
# v1.2.3

# The remote this repository belongs to.
rt git::remote
# origin
```

`git::remote` answers from `checkout.defaultRemote`, then the current branch's remote, then
the sole remote, and refuses when several exist and nothing says which. `git::latest_version`
and `git::release --push` both use it instead of assuming `origin`.

A fork still answers `origin`, because that is what its tracking branch says and it is the
right answer for releasing the fork. `git config checkout.defaultRemote upstream` is how you
say otherwise.

```shell
# HEAD is a commit main already took. Refuses on a shallow clone rather than answering
# from truncated history, where merge-base reports a genuine ancestor as not one.
rt git::assert_on_branch main

# The same question over the API, which needs no local history and so works on a shallow
# clone or a repository too large to fetch in full.
rt github::assert_on_branch main
```

`release::prechecks` runs the shape, the tree, the tag, the ordering and optionally the
branch and the registry in one call:

```shell
rt release::prechecks "$(uv version --short)" \
  --branch main \
  --check-registry-url "https://pypi.org/pypi/my-package/1.2.3/json"
```

The registry must answer 404. PyPI, the npm registry and crates.io all do for a version
they do not carry, and any other answer is a refusal rather than a guess.

## Waiting for things

```shell
# Wait for one workflow's run on a commit, and fail if that run failed.
rt github::await_workflow "$GITHUB_SHA" tests.yml

# Wait for a URL to start serving, backing off 15s, 30s, 60s, 120s, 240s.
# An index or a CDN takes time to serve what it has just accepted, and a short fixed
# wait fails releases that published correctly.
rt net::await_url "https://pypi.org/pypi/my-package/1.2.3/json"

# The status code, once, for the times you want to branch on it.
rt net::status "https://example.com/"
# 200
```

## Release bookkeeping

```shell
# What was written for this version, for a release body.
rt changelog::section 1.2.3
rt changelog::section 1.2.3 docs/CHANGELOG.md

# Refuse to republish over a release that already has assets.
rt github::assert_release_absent v1.2.3

# Tell another repository that a release shipped.
rt github::dispatch releasetools/homebrew-tap upstream-released version=v1.2.3
```

## GitHub Action

The `releasetools/cli` library can be installed via a GitHub workflow:

```yaml
steps:
  ...
  - uses: releasetools/cli@v0
  ...
```

A few customizations are available, if needed:

```yaml
steps:
  # Install releasetools
  - uses: releasetools/cli@v0

  # Customizations
  # with:
  #   # Pin a specific version (defaults to the version this action was released with)
  #   version: "vX.Y.Z"
  # env:
  #   # Configure the installation directory
  #   RELEASETOOLS_INSTALL_DIR: /home/runner/.local/share
  #   # Configure where binaries are linked (e.g. a directory that is already in PATH)
  #   RELEASETOOLS_BINARY_DIR: /home/runner/.local/bin

  # Check that `releasetools` was installed correctly
  - run: releasetools base::check_deps
```

### What each namespace needs

| namespace | needs |
| --- | --- |
| `base::` | nothing |
| `git::` | `git`, `grep` |
| `github::` | `gh`, authenticated through `GH_TOKEN` |
| `net::` | `curl` |
| `changelog::` | `awk`, `sed` |
| `release::` | whatever the checks it runs need |

Nothing is installed alongside the action, and GitHub-hosted runners carry all of it.

`base::check_deps` reports on every namespace at once and fails if any of them is missing a
command, so on a machine without `gh` it fails even for someone who only calls `git::`. The
error names the namespace.

`github::` commands ask the GitHub CLI, which resolves the repository from `GH_REPO` when
set and from the checkout's remote otherwise. `GITHUB_REPOSITORY` is not part of that, so a
workflow sets both:

```yaml
  - run: rt github::await_workflow "$SHA" tests.yml
    env:
      GH_TOKEN: ${{ github.token }} # no runner default
      GH_REPO: ${{ github.repository }} # = $GITHUB_REPOSITORY; gh reads GH_REPO
      SHA: ${{ github.sha }} # = $GITHUB_SHA
```

`GH_REPO` and `SHA` carry values the runner already publishes, as `GITHUB_REPOSITORY` and
`GITHUB_SHA`. The rename matters for the first: gh looks for `GH_REPO` and never at
`GITHUB_REPOSITORY`. `GITHUB_TOKEN` is not a default variable at all, so the token is the
one value here that has to be handed over rather than renamed.

## Developers

You can find the code and development guidelines in the [src/](./src/) directory.

Once you have completed and tested the code, see the [release instructions](./scripts/#release-a-new-version).

## License

Copyright &copy; 2025 Mihai Bojin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
