# Changelog

Newest first. Each entry says what changed for somebody running these commands. Dates are
ISO 8601, versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html), and
the shape follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

An entry earns its place by being observable. If running a command produces no different
result, no different output and no different exit code, it is not in here, whatever it cost
to build.

`release.yaml` reads the section for the version being released and uses it as the GitHub
release body, and refuses a tag whose version has no section. `/release-notes:draft <version>`
writes one; the plugin is declared in `.claude/settings.json`.

## [Unreleased]

### Added

- `git::remote` prints the remote this repository belongs to, resolved from
  `checkout.defaultRemote`, then the current branch's remote, then a sole remote. It refuses
  when several exist and nothing says which.
- `git::tags_at_head` prints the release tags on HEAD, highest version first.
- `git::assert_tag_version <version>` refuses unless a tag on HEAD names that version.
- `git::assert_tag_free <tag>` refuses unless the remote definitely does not carry the tag.
  A failure to ask the remote is a refusal, not a yes.
- `git::assert_on_branch [branch]` refuses unless the branch already took HEAD, and refuses
  outright on a shallow clone rather than answering from truncated history.
- `github::assert_on_branch [branch] [commit]` answers the same question over the compare
  API, which needs no local history.
- `github::await_workflow <sha> <workflow>` waits for one workflow's run on a commit.
- `github::assert_release_absent <tag>` refuses a tag whose release already carries assets.
- `github::dispatch <owner/repo> <event> [key=value ...]` sends a repository_dispatch event.
- `changelog::section <version> [file]` prints one version's changelog section.
- `net::status <url>` prints an HTTP status code; `net::await_url <url>` waits for a URL to
  serve, backing off across about 7.75 minutes.
- `release::prechecks <version>` runs the shape, the working tree, the tag, the ordering and
  optionally the branch and a registry URL.
- `install.sh` links `rt` alongside `releasetools`, and leaves a name it did not create.

### Changed

- `git::latest_version` and `git::release --push` use `git::remote` instead of assuming
  `origin`.
- `git::release` reuses a tag that already points at HEAD instead of failing, so a retry
  after a failed push no longer needs `--force`. It refuses a tag pointing anywhere else,
  and refuses to reuse an unsigned tag when `--sign` was asked for.
- `base::check_deps` now reports on `changelog::`, `net::`, `release::` and a `github::`
  that requires `gh`, so it fails on a machine without the GitHub CLI.

### Removed

- `github::get_version`. A GitHub-wide code search found its definition and one docs page
  and no caller. `v$(rt git::version_tag)` replaces it, and `--env` becomes
  `echo "VERSION=v$(rt git::version_tag)" >>"$GITHUB_ENV"`.
