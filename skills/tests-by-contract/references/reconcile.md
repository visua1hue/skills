# Reconcile

Reconcile mode prunes every test one subsystem owns, in one PR. A subsystem is a plugin, a package, or one core area. The value bar, retention bar, candidate evidence, and validation rules in [SKILL.md](../SKILL.md) apply to every lane. This file adds the order of work and lessons from a full reconcile. Each step has a completion criterion. Don't start the next step until it's met.

## 1. Baseline

Pin a `main` SHA. Record the subsystem's test and test-support line counts, and whether each test file passes or fails. Keep the baseline failures in a separate list. In one messaging-plugin reconcile, all three baseline failures were real delivery bugs, not stale tests.

Done when every in-scope test file has a recorded baseline result.

## 2. Lanes and inventory

Split the tests into **lanes** along production owners, not file-name prefixes. For a messaging plugin the lanes were accounts, commands, context, dispatch, inbound, outbound, persistence, transport, shared, harness, and end-to-end and manual QA tests. Include the subsystem's test cases inside shared core suites, and its end-to-end harness tests.

Done when every test file and end-to-end test the subsystem owns belongs to exactly one lane.

## 3. Read-only ledger per lane

Give each lane to its own read-only agent. The agent reads every assigned test in full, including parameter tables. It also reads the production owners, their entry points, callers, git history, and CI routing. It writes each test declaration into a **ledger** with one mark. A parameterized test (`it.each`, `test.each`, table-driven) counts as one declaration, unless its rows need different marks. Then mark each row.

- `R` (retain): name the contract and the bug it catches. A test that only moves to a better-named file stays `R`, with the move noted.
- `F` (fix): keep the contract, repair the assertion. Example: a negative check that still passes when only one of several items is missing.
- `C` (consolidate): name the test that absorbs the assertion first. That can be a sibling table case, a suite at a stronger boundary, or the shared owner in another package.
- `D` (delete): name the proof that remains, or explain why no contract exists.

Judge a test by its assertions, not its name. One test named for retiring a progress window asserted that the window was _not_ cleared.

Done when every declaration in the lane has a mark and a line of evidence.

## 4. Layer plan per lane

The ledger is input, not the edit list. A second read-only pass starts from the ledger and looks for the redundant **layer**. In one reconcile, several dispatch suites replayed the same shared compositor through one mocked preview, while stronger real-stream and HTTP-fixture suites already covered it. Name the **keeper** suite for each contract. Prefer a test at the real transport boundary with a fake network over one with a mocked collaborator. Fix any ledger errors this pass finds.

Done when each lane plan names its retired files, its keeper per contract, the assertions to move into keepers, and the test-only seams the plan frees up.

## 5. Cutover

Edit one lane at a time. Route all changes to shared harnesses and support files through one agent, one change at a time. With each lane, remove the seams it frees up: injection parameters, getters, reset exports, and indirection layers. Register moved suites in CI routing and test inventories. Update any size or coverage baselines CI enforces. Add durable test-ownership rules to the subsystem's `AGENTS.md`, based on mistakes this reconcile actually found.

Done when every lane plan is applied and each lane's keepers pass.

## 6. Preservation review

Before claiming completion, have independent reviewers compare the deleted coverage against the keepers, one reviewer per group of boundaries. They look for contracts that lost their only proof, and for new assertions that can't fail, such as a rejection row the production code never reaches. One review found nine real gaps and one unreachable assertion.

For each restored contract, make one deliberate **mutation** in the production owner and confirm the keeper fails. Then restore the source byte for byte.

Done when every reported gap is restored, or rejected with evidence from source, and every restored contract has a caught mutation.

## 7. Product defects

A baseline failure that survives into a keeper is a bug report. Fix it at the owner in a separate commit. Prove the fix through the real user flow, with a **control** run that reverts the fix and shows the old behavior. Log unrelated product problems as follow-ups instead of fixing them in the reconcile.

Done when each repaired defect has a failing control and a passing candidate on the same harness.

## 8. Merge and hand off

A reconcile branch outlives many `main` commits. Merge `main` into it rather than rebasing. This is an exception to the rebase rule in `git-stack-flow`, because a rebase replays conflicts once per commit on a long branch. When `main` changed a file the reconcile deleted, keep the deletion and port the new contract into the keeper. Confirm every new regression test from `main` still has a home. Rerun the whole subsystem suite and repeat proof in the running app (eng-principles P11) on the merged head.

On a diff this large, review tools may see only part of the file list.

Hand off with the [SKILL.md](../SKILL.md) report, plus:

- baseline and final test and test-support line counts, with production counted separately
- lanes, retired layers, and keepers
- preservation gaps found, and the mutation that proved each one
- product defects, with control and candidate proof
