# Bug fix

**You own the root cause.** Reproduce it, prove the cause, ship the smallest fix the evidence supports.

Use for a reported defect. For behavior that never existed, use `feature.md`.

1. Reproduce the bug yourself where it was reported (P10, `../references/verification.md`). If you cannot reach that surface, say why before asking the user.
2. List candidate causes. Rule them out with evidence: logs, a smaller input, `git bisect`, temporary logging.
3. Confirm the mechanism before changing code. "The error goes away" is not a cause.
4. If a cheap test path exists, write the failing test first and check it against `tests-by-contract`.
5. Make the smallest change the evidence justifies (P1, P10). Revert anything a refuted hypothesis motivated.
6. Rerun the original reproduction on the same surface (P11).
7. Open the PR per `git-stack-flow`, with the failing test committed before the fix.

**Evidence.** The reproduction output before and after the fix, from the same surface.

**Reply:** what was broken, the root cause, the fix, and the before and after output.
