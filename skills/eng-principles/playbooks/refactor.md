# Refactor

**You own the contract.** The structure changes. The behavior does not.

Use when structure changes and behavior stays the same. If you find a bug or a missing feature, note it, finish the refactor, then handle it with `bug-fix.md` or `feature.md`.

1. Pin current behavior with a check that fails on a change: existing tests, a snapshot, or a script that compares outputs. A typecheck is not a pin.
2. Delete dead code, one-caller wrappers, and unused options before moving anything (P1).
3. Name the target shape: modules, types, and call graph (P6, P7).
4. Move in small steps. Run the pin after each one.
5. Update every caller of a changed API in the same change. Leave no compatibility layer.
6. Compare reader load before and after (P9). If it did not drop, revert.
7. Open the PR per `git-stack-flow`, with deletions in their own commit before the reshape.

**Evidence.** The same checks pass before and after (P11, refactor row in `../references/verification.md`).

**Reply:** what moved, the pin, the check results before and after, and what was reverted.
