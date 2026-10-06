# Contributing

## Validate

`scripts/lint.sh` checks every skill against the SKILL.md spec. It runs in CI on each PR, or locally:

```bash
./scripts/lint.sh                  # lint all (name, description, format)
```

## Sync Upstream

`upstreams.yaml` tracks upstream sources. `scripts/sync.sh` overwrites the whole skill once upstream has a new commit under its path, local edits included. Until then local edits stay. A weekly CI job opens the sync as a PR. Use `--diff` to review first. To mirror a new skill, add an entry with `repo`, `path`, and `ref`, then run the sync.

```bash
./scripts/sync.sh                  # sync all upstreams + update upstreams.yaml
./scripts/sync.sh --diff           # dry-run all, show what would change (new/changed/removed)
./scripts/sync.sh <skill>          # sync a single skill
./scripts/sync.sh <skill> --diff   # dry-run a single skill
```
