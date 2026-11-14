# Architecture review

**You own the shortlist.** Find where the structure costs the most, rank it, and change nothing until the user picks.

Use when asked to assess or improve the structure of existing code. Once the user picks a candidate, switch to `refactor.md`. For a question about one design choice, use `investigation.md`.

1. If the user named an area, start there. Otherwise find hotspots: files that change often and are large. `git log --since=1.year --format= --name-only | sort | uniq -c | sort -rn | head -20` lists the most changed files.
2. Read the decision records and ARCHITECTURE.md for those areas, and search open issues and PRs that touch them.
3. Read the code at each hotspot. Apply the deletion test (P15) and compare coupling with distance (P16), using `../references/architecture.md`. A metric alone is not evidence. Name the file and the lines that show the problem.
4. Rank 3 to 5 candidates by how often the code changes and how far each change spreads. For each, give the files, the problem, the proposed shape, the evidence, and any record, issue, or PR that touches it.
5. When a candidate conflicts with an accepted decision record, cite the record and its reopen condition. Rank the candidate only if a new fact meets that condition. Otherwise list it once under the record it conflicts with. Link an existing issue or PR instead of proposing a duplicate.
6. Stop and let the user pick. If the user rejects a candidate for a lasting reason, offer to draft a decision record for team review (P12).

**Evidence.** For each candidate, the files and lines read, and the change counts from step 1.

**Reply:** the ranked candidates, the top recommendation and why, and the records, issues, and PRs cited.
