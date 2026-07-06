# Release notes

`build_dmg.sh <version> --release` picks the GitHub release body in this order:

1. `release_notes/v<version>.md` — hand-written notes for that version (preferred).
2. `RELEASE_NOTES.md` in the repo root — generic fallback.
3. Otherwise `gh --generate-notes` auto-builds a "What's Changed" from commits since the last tag.

**Workflow:** before releasing version `X.Y.Z`, add `release_notes/vX.Y.Z.md` (see `v1.1.0.md`
for the format), then run `./build_dmg.sh X.Y.Z --release`.
