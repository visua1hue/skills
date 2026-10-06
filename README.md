![Agent Skills](.github/assets/preview.png)

<div align="center">

Agent Skills, built by you, run by agents. Follows the [Agent Skills](https://agentskills.io/home) open standard.

Curated Agent Stack, production-tested. Context, loaded when it matters.

</div>

## Agent Skills

Skills are either **Model-invoked**, where the agent activates them when your request matches, or **User-invoked** via a slash command like `/triage`.

**Upstream** skills are mirrored, not forked. Their authors own them; a weekly sync keeps them updated.

### Engineering

- [git-stack-flow](skills/git-stack-flow/): Commit/branch conventions, PR flow, and worktree audit
- [eng-principles](skills/eng-principles/): Design and verification principles for code
- [tests-by-contract](skills/tests-by-contract/): Authoring gate and audit for test value
- [typescript-magician](skills/typescript-magician/): Complex generics, type guards, and strict typing. **Upstream**, Author: [Matteo Collina](https://github.com/mcollina/skills/tree/main/skills/typescript-magician)
- [motion-sense](skills/motion-sense/): Animation purpose, timing, and CSS technique
- [motion-engine](skills/motion-engine/): Performant animations with CSS, WAAPI, and Motion.dev
- [ui-baseline](skills/ui-baseline/): Type/spacing tokens, component patterns, and adaptive CSS
- [triage](skills/triage/): GitHub issue and PR triage state machine
- [unslop](skills/unslop/): Strip AI tells and filler from writing. **Upstream**, Author: [Lauren Tan](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop)

### Workflow

- [obsidian-cli](skills/obsidian-cli/): Read, search, and manage Obsidian via CLI. **Upstream**, Author: [Steph Ango](https://github.com/kepano/obsidian-skills/tree/main/skills/obsidian-cli)

## Extended Layer

Recommended, not required. Extra tools for the agent, over MCP.

- Type: **MCP** | [fff](https://github.com/dmtrKovalenko/fff)
- Type: **MCP** | [Chrome DevTools](https://github.com/ChromeDevTools/chrome-devtools-mcp)
