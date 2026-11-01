# Call tree

A Scope section for changes that add or reroute a call path across 3 or more files. Shows the reviewer where to start and what each entry point reaches. Any other change lists paths in reading order instead.

## Build it from the diff

- Entry points: changed functions nothing else in the diff calls. Max 2. With more, keep the two with the most new nodes and list the rest as paths.
- An edge exists only when the call is in the diff's added or changed lines. Never open files outside the diff to find callers. That's blast radius, scored in [merge-risk.md](merge-risk.md).
- Symbol names only. No arguments, no line numbers.
- Existing code appears only as an entry point or as a link between two changed nodes. Drop existing leaves.
- A subtree reached from both entry points repeats under each.
- Cap 15 nodes, depth 4. Over the cap, cut existing nodes first, then collapse a subtree to its top node plus `…`.

## Render

Code block with `├─`, `└─`, `│`. Markers: `+` new, `~` changed, none for existing. File name after the symbol only when it differs from the parent's. No column alignment. One legend line below the block.

```
POST /login  routes/auth.ts
├─ + validateCredentials  auth/validate.ts
├─ + rateLimit.check  middleware/rate-limit.ts
└─ ~ Session.create  session.ts
   └─ + Session.bindDevice
      └─ ~ sessions.insert  db/sessions.ts

Session.refresh  session.ts
├─ + Session.verifyDevice
│  └─ ~ sessions.find  db/sessions.ts
└─ ~ Session.rotate
   ├─ + Token.sign  auth/token.ts
   └─ ~ sessions.update  db/sessions.ts
```
`+` new, `~` changed
