# Refactor

**You own the contract.** The structure changes. The behavior does not.

Use when structure changes and behavior stays the same. If you find a bug or a missing feature, note it, finish the refactor, then handle it with `bug-fix.md` or `feature.md`.

1. Pin current behavior with a check that fails on a change: existing tests, a snapshot, or a script that compares outputs. A typecheck is not a pin.
2. Delete dead code, one-caller wrappers, and unused options before moving anything (P1).
3. Name the target shape: modules, types, and call graph (P6, P7). Each module passes the deletion test (P15), and distant modules share only a contract (P16).
4. Move in small steps. Run the pin after each one.
5. Update every caller of a changed API in the same change. Leave no compatibility layer, unless callers can't change in the same release, as with a published package, a public API, or stored data. Then expand, migrate, contract (P16).
6. Compare reader load before and after (P9), counting interface size and the files a typical change touches. If neither dropped, revert.
7. Encode the new boundary as a check, and update ARCHITECTURE.md if the codemap changed (P5, module boundary row in `../references/verification.md`).
8. Open the PR per `git-stack-flow`, with deletions in their own commit before the reshape.

**Evidence.** The same checks pass before and after, and the boundary check fails on a planted violation (P11, refactor row in `../references/verification.md`).

**Reply:** what moved, the pin, the check results before and after, and what was reverted.
