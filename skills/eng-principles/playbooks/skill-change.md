# Skill change

**You own what the next agent does.** Change the instruction, then show that agent behavior changed.

Use for an edit to a skill, a playbook, or an agent instruction file such as `AGENTS.md` or `CLAUDE.md`.

1. State the behavior change in one sentence: what agents do now, and what they should do instead.
2. Read the current file in full and the files it links. If another skill already covers the rule, edit it there instead of adding a copy.
3. If the change draws on outside sources, record each source and its license. Rewrite their text instead of copying it.
4. Write down each decision and its reason before editing.
5. Edit. Keep only text that changes a decision. Point to other skills by name instead of restating them. A correction that keeps coming back becomes a lint rule or check, not more text (P5).
6. Run `neural-antipattern` over the changed text.
7. Run the project's skill lint or validator, if it has one.
8. If agent behavior should change, eval it. Write the cases and the rubric before the edit, run them against the old and the new text, and score blind.
9. Open the PR per `git-stack-flow`.

**Evidence.** Lint output, plus eval scores before and after, or a statement that the change does not alter behavior.

**Reply:** the behavior change, the decisions, and the lint and eval results.
