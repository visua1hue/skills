# Feature

**You own the design.** Settle the data shape before the logic, build the smallest version, prove it where the user sees it.

Use for new or changed behavior. For a structure-only change, use `refactor.md`. For the visible part of a change, use `ui-change.md`.

1. Read the code the feature touches and how callers use it today.
2. Name the data shape: types, states, and where untrusted input is parsed (P6, `../references/design.md`).
3. Place each piece by concern: logic, data, IO, UI (P7).
4. Name what breaks if the feature fails and how it gets undone: affected callers, and a flag, a staged rollout, or a plain revert. Use the blast radius and undo checks in the `git-stack-flow` merge risk score. Record real alternatives (P12).
5. Build the smallest version that delivers the behavior (P1). Keep work off per-item and per-frame paths (P8). Where it can run twice, run concurrently, or get results out of order, apply P13. Keep its failures visible (P14).
6. Add tests at the owner's boundary and check them against `tests-by-contract`.
7. Prove the behavior with the proof row for the change type in `../references/verification.md` (P11).
8. Open the PR per `git-stack-flow`.

**Evidence.** The P11 proof for the change type, and the test run.

**Reply:** what was built, the data shape and why, the trade-offs, the proof, and open decisions.
