---
name: tests-by-contract
description: Authoring gate, audit, and subsystem reconcile for automated tests. Rejects tests that prove mocks or implementation instead of behavior. Use when writing, changing, reviewing, or pruning tests.
---

# Tests by contract

Every test must protect a contract: observable behavior, an invariant, or an interface other code depends on. The same value bar applies in three modes.

- **Authoring.** Gate every new or changed test before it lands.
- **Audit.** Sweep a focused area for tests that re-assert source, duplicate stronger proof, couple to implementation, or keep test-only production code alive. Ship each sweep as its own PR. Aim for confidence, not deletion count.
- **Reconcile.** Prune every test one module, package, or plugin owns, in one PR. Read [references/reconcile.md](references/reconcile.md) before starting.

Terms used below:

- **Owner.** The production module responsible for a behavior.
- **Boundary.** The owner's real entry point, as production callers use it.
- **Seam.** An export, flag, wrapper, or injection hook that exists only so a test can reach inside.

## Authoring gate

Answer four questions before adding a test. If one has no answer, don't add the test yet.

1. What observable behavior, invariant, or independent contract does it protect?
2. What credible regression makes it fail?
3. Why doesn't existing coverage already catch that failure? Each contract has one primary test at the strongest boundary. A test at another layer needs its own risk, such as a transport or lifecycle failure the primary test can't reach. Extend a table-driven case or shared fixture rather than writing a near-duplicate, and consolidate duplicated setup in the same change.
4. Does it need a seam that no production caller needs? If so, test at the real boundary instead.

Then check the test against every [junk pattern](#junk-patterns). A match fails the gate unless the [retention bar](#retention-bar) names the contract the test guards on its own. A test that breaks under a behavior-preserving refactor asserts implementation. Rewrite it at the owner's boundary before landing it.

A bug regression test must fail on the pre-fix code for the intended reason, then pass after the fix at the owner. If it never failed, it proves the mock, not the fix. One regression test at the owner covers the bug. Don't replay the same scenario at every layer it crosses.

## Junk patterns

The authoring gate rejects new tests that match these, and audits hunt for existing ones. Numbers are stable ids. Cite them in reviews (`T6`). A removed pattern leaves a gap, and new patterns get the next number.

1. Coverage probes with no assertion.
2. Self-comparisons and identity copiers.
3. Copied fixtures, inventories, manifests, or export lists.
4. Exact greps for source, imports, or strings.
5. Tests of a private predicate or call shape that a real boundary test already covers.
6. Repeat invocations of the same contract.
7. Per-module replays of a shared helper's tests.
8. Tests that exist only to keep test-only exports, globals, or wrappers alive.
9. Dead production code whose only callers are tests.
10. Expected values computed by the helper or renderer under test.
11. Mocks that implement the asserted behavior, or one identical mock standing in for different APIs.
12. Fixtures that supply the result, state, or event order the code under test should produce. Also persistence asserted against a store the code path never writes to.
13. Capability tests that restate a declared flag instead of exercising the delivery or acknowledgement the flag promises.
14. Negative controls that pass for an unrelated reason, such as a denial from a different guard or a rejection the production path never reaches.
15. Names or fixtures that promise more than the input exercises, such as a "retires the window" test that asserts the window was not cleared.

## Value bar

A test earns its maintenance cost by protecting behavior, catching a credible regression, or enforcing a contract that matters on its own. In an audit, an existing test that has to change when source is reorganized without changing behavior is a suspect, not an automatic delete. The authoring gate still rejects new tests like that.

Before judging a candidate, read the whole test and its owner, the entry point, callers, callees, sibling implementations, overlapping tests, CI routing, and git history. Read the root and nearest `AGENTS.md` files first. When a test claims behavior that comes from a dependency, read the dependency's source or types.

## Discovery

Discovery is read-only. Report evidence before editing anything. For a broad scope, run parallel discovery lanes split along the repository's top-level owners, for example:

- core and packages
- plugins or extensions
- UI, apps, scripts, and tooling
- a cross-cutting sweep for one junk pattern

Outside reconcile mode, report a few high-confidence candidates, not a long speculative list.

## Retention bar

Keep a test when it alone enforces one of these contracts: public API, SDK, protocol, config, migration, storage, security, platform, default value, exact output format (prompt, wire, file), generated cross-language code, package, release, or architecture. Also keep:

- call-order assertions when the order is observable behavior
- regression tests with a credible failure mode
- source inspection when it is the cheapest independent guard, meaning it fails when the contract changes (a user-facing key, byte, or path) and survives renaming identifiers
- a test that fails on the baseline. Treat it as a possible product bug, reproduce it, and fix the owner instead of deleting the test.

Being static or slow is not a reason to delete a test. A test that looks like it mirrors implementation may still be the only proof of a contract. Prove otherwise before removing it.

## Candidate evidence

Record every field before editing. A candidate with a missing field is not ready to delete.

- exact test name and location
- the failure it can actually detect
- non-test callers of the production code or seam it covers
- the stronger proof that remains at the boundary, or why no proof is needed
- git history and the reason the test or seam exists
- production or test-support code the deletion frees up
- risk, and the focused command that validates the change

## Edit shape

Work one owner at a time, as one coherent batch. Delete obsolete test-only exports, globals, wrappers, and dead production paths. Don't keep aliases for them. Move retained regression tests to the owner's suite. Merge repeated package or dependency assertions into one generic contract test.

Aim for fewer production lines, not more. Don't add replacement tests that restate the same implementation. Don't delete uncertain candidates to raise the count.

## Validation

Don't edit source or tests while a test run is in progress in the checkout. Follow the repository's testing rules in `AGENTS.md` and its CI config.

1. Run the owner's tests and its siblings' tests with the project's test runner, filtered to the changed paths.
2. When you remove a source grep or output snapshot, run the script or dry-run that owns the real contract.
3. Format the changed files, then run `git diff --check`.
4. Run the checks the repository requires for changed files: lint, typecheck, and the tests CI would run.
5. Read `git diff --numstat`. Report production and tooling lines separately from test and test-support lines.
6. After the final edits, run `/code-review`.

## Landing and continuation

Commit, push, open a PR, or merge only when the user authorizes it. Follow `git-stack-flow`. Land one PR at a time. After it merges, pull current `main` and rerun read-only discovery for the next high-confidence batch.

## Handoff

Report:

- root cause and the junk patterns removed
- simplifications in production code
- retained false positives and why they still matter
- the focused and full test runs you actually ran
- production versus test line counts
- PR and merge state
- named follow-ups
