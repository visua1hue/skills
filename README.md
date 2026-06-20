# Skills

Core Agent-Driven Skills for AI-Native development

**Install** (symlink)

```bash
for d in ~/Development/skills/*/; do ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"; done
```

**Sync upstream**

```bash
./sync.sh                    # check all upstreams for changes
./sync.sh triage             # diff triage vs upstream
./sync.sh triage --apply     # fetch + overwrite + update MANIFEST
```
