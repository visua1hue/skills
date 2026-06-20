# Skills

Agent-Driven Skills for **AI-Native** development. Learn more about the open standard at [Agent Skills](https://agentskills.io/home).

## Overview

- [emil-design-eng](emil-design-eng/): UI polish and animation philosophy — by [Emil Kowalski](https://github.com/emilkowalski)
- [motion-engine](motion-engine/): performant animations with CSS, WAAPI, and Motion.dev
- [perf-audit](perf-audit/): Core Web Vitals auditing via Chrome DevTools MCP and Lighthouse
- [typescript-magician](typescript-magician/): complex generics, type guards, and strict typing — by [Matt Pocock](https://github.com/mattpocock)
- [council](council/): parallel read-only subagents that investigate a codebase area, then synthesize findings
- [triage](triage/): GitHub issue and PR triage state machine

### Validate

`lint.sh` checks every skill against the SKILL.md spec — runs in CI on each PR, or locally:

```bash
./lint.sh                          # lint all (name, description, format)
```

### Sync Upstream

`MANIFEST.yaml` tracks upstream sources. `sync.sh` overwrites your local copy from them — use `--diff` to review first.

```bash
./sync.sh                          # sync all upstreams + update MANIFEST
./sync.sh --diff                   # dry-run all — show what would change (new/changed/removed)
./sync.sh <skill>                  # sync a single skill
./sync.sh <skill> --diff           # dry-run a single skill
```

## Extended Layer

- Type: MCP | [Chrome DevTools](https://github.com/ChromeDevTools/chrome-devtools-mcp)
- Type: MCP | [MDN](https://github.com/mdn/mcp)
