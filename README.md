# Skills

Agent-Driven Skills for AI-Native development. Learn more at [agentskills.io](https://agentskills.io/home).

**Sync Upstream**

`MANIFEST.yaml` tracks upstream sources. `sync.sh` diffs your local copy against them — review before applying.

```bash
./sync.sh                          # dry-run all upstreams — show what changed
./sync.sh --apply                  # fetch + overwrite all upstreams + update MANIFEST
./sync.sh <skill>                  # dry-run a single skill
./sync.sh <skill> --apply          # fetch + overwrite single skill + update MANIFEST
```

## Beyond Skills

- [Chrome DevTools](https://github.com/ChromeDevTools/chrome-devtools-mcp) (MCP)
- [MDN](https://github.com/mdn/mcp) (MCP)
