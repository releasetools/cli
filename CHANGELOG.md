# Changelog

Newest first. Each entry says what changed for somebody running these commands. Dates are
ISO 8601, versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html), and
the shape follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

An entry earns its place by being observable. If running a command produces no different
result, no different output and no different exit code, it is not in here, whatever it cost
to build.

`release.yaml` reads the section for the version being released and uses it as the GitHub
release body, and refuses a tag whose version has no section. `/release-notes:prepare <version>`
writes one; the plugin is declared in `.claude/settings.json`.

## 0.4.0 - 2026-09-20

### Added

- `version::bump <version> --command '<template>' [--manifest <file>] [--dir <path>]` runs
  the command a project declares for setting its version, substituting `{version}`, and
  then refuses if the manifest did not take it. Every ecosystem ships that command --
  `uv version`, `npm version --no-git-tag-version`, `cargo set-version` -- so nothing here
  parses or rewrites a manifest, and the project says which command it is in the `bump`
  key of `.releasetools.yaml`. A manifest already declaring the version is left alone, so
  running it twice changes nothing and a resumed release does not double-bump.

## 0.3.0 - 2026-09-11

### Changed

- `git::version_tag` prints the tag with its `v`, and `git::latest_version` prints the
  version without one. A `*_tag` is what `git tag` accepts; a `*_version` is what a
  manifest, a chart and a package index carry, so the name now says which you get.

  **This breaks any caller reading either value.**

  | | before | after |
  | --- | --- | --- |
  | `rt git::version_tag` | `1.2.3` | `v1.2.3` |
  | `rt git::latest_version` | `v1.2.3` | `1.2.3` |

  `git::version_or_sha` and `git::tags_at_head` are unchanged, and every command that takes
  a version or a tag still accepts either form. Only what comes out moved.

### Choices

Both commands could have kept their output and gained new names instead. The output moved
because the names are the public surface: somebody reaching for `version_tag` should get a
tag, and the next reader should not have to check which. A code search across every org and
then globally found one caller outside this repository, and its `${VERSION#v}` becomes a
no-op rather than wrong.

## 0.2.0 - 2026-09-11

### Changed

- `git::is_dirty` answers with its exit status instead of printing a string. It exits 0
  when the working tree has uncommitted changes, 1 when it is clean, and prints nothing.

  **This breaks any caller that read the printed suffix.** Build it from the answer:

  ```bash
  if rt git::is_dirty; then sha="$sha-dirty"; fi
  ```

  It used to print `-dirty` or an empty line and exit 0 either way, so the call its name
  invites ran its body whatever the tree looked like:

  ```console
  $ rt git::is_dirty && echo "DIRTY" || echo "clean"
  DIRTY          # on a clean tree
  ```

  A working tree that cannot be read is now reported as dirty, with the reason on stderr.
  `git::head_sha` is unaffected and still prints `8a7a7b6-dirty`.

### Choices

Renaming it to say what it returned, `git::dirty_suffix`, would have kept every caller
working. The predicate won because both callers here wanted a yes or no rather than the
string, and a code search across every org and then globally found none outside this
repository. The rename would have left a command that reads as a question and cannot be
used as one, under a longer name.

## 0.1.0 - 2026-09-11

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
