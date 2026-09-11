# Build scripts and helpers

This directory contains scripts used to generate artifacts and trigger releases.

## Release a new version

Four steps, in order. Each one is checked by something, so skipping one fails the release
rather than shipping a wrong one.

1\. Bump the `default:` version in [action.yml](../action.yml) and commit it.

`git::release --major` force-moves the `v0` tag onto every release, so a consumer writing
`uses: releasetools/cli@v0` installs whatever that default names. Left stale, `@v0` keeps
serving the previous release while every test passes. `scripts/assert-action-version.sh`
runs inside `tag.sh` and refuses to tag until the two agree.

2\. Write the changelog entry.

```shell
/release-notes:draft X.Y.Z
```

That rules on every commit since the previous tag and writes the entry into
[CHANGELOG.md](../CHANGELOG.md) under `## X.Y.Z - <date>`. The plugin is declared in
`.claude/settings.json`; installing it by hand is
`claude plugin marketplace add releasetools/agent-plugins` then
`claude plugin install release-notes@release-tools`.

`release.yaml` reads that section back out as the GitHub release body and fails when the
version has no section, so this is not optional.

3\. Tag and push.

```shell
scripts/tag.sh vX.Y.Z --major --sign --push # X, Y, Z are integers
```

`--major` is what moves `v0` onto the new release, and `uses: releasetools/cli@v0` resolves
through that tag, so without it every consumer keeps the previous release no matter what
step 1 said. `--sign` because every release tag here carries a signature.

4\. Watch `release.yaml`, then `test-release.yaml`.

## Retrying a release

A tag names one commit forever. When a push fails partway, run the same command again:
`git::release` reuses a tag that already points at HEAD and goes straight to the push, and
refuses one that points at any other commit.

`--force` moves the tag on the remote. Reach for it only to correct a tag that was pushed
to the wrong commit and that nobody has installed, and prefer the next patch version to
anything else.
