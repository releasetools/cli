# Build scripts and helpers

This directory contains scripts used to generate artifacts and trigger releases.

## Release a new version

After coding and testing new code, run the following command to tag and trigger a new release.

```shell
scripts/tag.sh vX.Y.Z --push # X, Y, Z are integers

# if you are replacing a release, use the --force flag, e.g.:
scripts/tag.sh vX.Y.Z --force --push
```
