<a id="top"></a>

![pi-pane preview](.github/assets/preview.png)

<div align="center">

Agent Skills. **Built by you, run by agents**. Learn more about the open standard at [Agent Skills](https://agentskills.io/home).

</div>

## Agent Skills <sup><small>[⌃](#top)</small></sup>

Skills are either **Model-invoked** — Agents auto-activates them when your request matches — or **User-invoked** via a slash command like `/triage`.

### Model-invoked

- [typescript-magician](typescript-magician/): Complex generics, type guards, and strict typing — by [Matteo Collina](https://github.com/mcollina)
- [motion-sense](motion-sense/): Animation purpose, timing, and CSS technique
- [motion-engine](motion-engine/): Performant animations with CSS, WAAPI, and Motion.dev
- [svg-path-animation](svg-path-animation/): Line-drawing, path morphing, and motion-along-a-path
- [adaptive-layout](adaptive-layout/): Solid component states, touch handling, and adaptive CSS
- [typeset](typeset/): Type scale, spacing, and line-height that actually varies

### User-invoked

- [exec](exec/): Orchestrate parallel read-only subagents, then synthesize (default n=5)
- [triage](triage/): GitHub issue and PR triage state machine

## Commands <sup><small>[⌃](#top)</small></sup>

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

## Extended Layer <sup><small>[⌃](#top)</small></sup>

- Type: **MCP** | [fff](https://github.com/dmtrKovalenko/fff)
- Type: **MCP** | [Chrome DevTools](https://github.com/ChromeDevTools/chrome-devtools-mcp)
- Type: **MCP** | [MDN](https://github.com/mdn/mcp)
