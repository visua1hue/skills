# Skills

Agent-Driven Skills for **AI-Native** development. Learn more about the open standard at [Agent Skills](https://agentskills.io/home).

## Overview

Skills marked with **\*** are fetched/maintained externally.

- [emil-design-eng](emil-design-eng/)**\***: UI polish and animation philosophy
- [motion-engine](motion-engine/): performant animations with CSS, WAAPI, and Motion.dev
- [perf-audit](perf-audit/): Core Web Vitals auditing via Chrome DevTools MCP and Lighthouse
- [typescript-magician](typescript-magician/)**\***: complex generics, type guards, and strict typing
- [triage](triage/): GitHub issue and PR triage state machine

### Sync Upstream

`MANIFEST.yaml` tracks upstream sources. `sync.sh` diffs your local copy against them — review before applying.

```bash
./sync.sh                          # dry-run all upstreams — show what changed
./sync.sh --apply                  # fetch + overwrite all upstreams + update MANIFEST
./sync.sh <skill>                  # dry-run a single skill
./sync.sh <skill> --apply          # fetch + overwrite single skill + update MANIFEST
```

## Extended Layer

- Type: MCP | [Chrome DevTools](https://github.com/ChromeDevTools/chrome-devtools-mcp)
- Type: MCP | [MDN](https://github.com/mdn/mcp)
