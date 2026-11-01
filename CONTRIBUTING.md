# Contributing

## Validate

`scripts/lint.sh` checks every skill against the SKILL.md spec. It runs in CI on each PR, or locally:

```bash
./scripts/lint.sh                  # lint all (name, description, format, playbooks)
```

## Credits

When to credit: a skill copies or adapts outside text, or takes its structure from one source. Doc links and single facts need no credit.

How: add an entry to the skill's `CREDITS.md`, written as `- Name, [source](url), License.` followed by indented sub-bullets on what you used. Lint checks the format.

Mirrored skills: sync deletes files the upstream does not have, so they get no `CREDITS.md`. `upstreams.yaml` records the source repo, and the README lists them as **Upstream** with the author.

## Sync Upstream

`upstreams.yaml` tracks upstream sources. `scripts/sync.sh` overwrites the whole skill once upstream has a new commit under its path, local edits included. Until then local edits stay. A weekly CI job opens the sync as a PR. Use `--diff` to review first. To mirror a new skill, add an entry with `repo`, `path`, and `ref`, then run the sync. Set `path: .` when the skill is the upstream repo root, and list the files and dirs to keep under `include` so the rest of that repo stays out.

```bash
./scripts/sync.sh                  # sync all upstreams + update upstreams.yaml
./scripts/sync.sh --diff           # dry-run all, show what would change (new/changed/removed)
./scripts/sync.sh <skill>          # sync a single skill
./scripts/sync.sh <skill> --diff   # dry-run a single skill
```
