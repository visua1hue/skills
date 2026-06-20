# Skills

Agent-Driven Skills for **AI-Native** development. Learn more about the open standard at [Agent Skills](https://agentskills.io/home).

## Overview

- `emil-design-eng` — UI polish and animation philosophy
- `motion-engine` — performant animations with CSS, WAAPI, and Motion.dev
- `perf-audit` — Core Web Vitals auditing via Chrome DevTools MCP and Lighthouse
- `typescript-magician` — complex generics, type guards, and strict typing
- `triage` — issue and PR triage state machine

### Sync Upstream

`MANIFEST.yaml` tracks upstream sources. `sync.sh` diffs your local copy against them — review before applying.

```bash
./sync.sh                          # dry-run all upstreams — show what changed
./sync.sh --apply                  # fetch + overwrite all upstreams + update MANIFEST
./sync.sh <skill>                  # dry-run a single skill
./sync.sh <skill> --apply          # fetch + overwrite single skill + update MANIFEST
```

## Extended Layer

- MCP — [Chrome DevTools](https://github.com/ChromeDevTools/chrome-devtools-mcp)
- MCP — [MDN](https://github.com/mdn/mcp)
