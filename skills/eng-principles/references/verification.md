# Verification principles

Detail for P11. The steps for P10 are in `../playbooks/bug-fix.md`.

## P11. Prove it works

Typecheck, lint, and build prove the code compiles. They do not prove behavior. Unit tests prove the branches they cover, not that the bug is gone where the user saw it.

Match the check to the change:

| Change | Proof |
| --- | --- |
| UI | Run the app and walk the changed flow. No new console errors. Screenshot or DOM state |
| CLI or TUI | Run the command with real input. Captured output |
| API or backend | Call the changed endpoint or function. Status and response body, including the error and unauthorized paths |
| Data or migration | Run it on realistic data. Before and after counts or samples |
| Performance | The same measurement before and after the change. Both numbers |
| Refactor | Behavior unchanged: the same checks pass before and after |

Use the project's own scripts and tools for these checks. Its `AGENTS.md` or `package.json` names them.

A check you could not run is "unverified", not "passed". "Inconclusive" is not a pass either. Say which checks you skipped and why.

The "done" reply states what was checked, where, and the evidence.
