---
name: neural-antipattern
description: Patterns that mark text as machine-written, with the fix for each. Covers brevity, filler, AI vocabulary, puffery, invented jargon, metaphor, sentence shape, punctuation, and formatting. Use when writing or editing docs, READMEs, commit messages, PRs, code comments, or skill text, and when asked to tighten, simplify, or de-slop writing. Applies to prose, not code.
---

# Neural antipattern

Patterns that mark text as machine-written, and the fix for each. Numbers are stable ids. Cite them in replies and reviews (`N12`). A removed rule leaves a gap.

## Process

1. Scan the text for the patterns below.
2. Rewrite. Keep the meaning and the intended tone.
3. Leave code, commands, and quoted text alone.

## Brevity

1. **Concise first.** Use the shortest wording that keeps the meaning. Chat replies and commit messages may drop articles and use fragments. When brevity conflicts with another rule here, brevity wins.
2. **No apologies, hedging, or meta-commentary.** Cut "Sorry for the confusion", "I should note that", "Let me explain". "could potentially possibly be argued that it might" becomes "may".
3. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!" Remove.
4. **Sycophantic tone.** "Great question! You're absolutely right!" Respond directly.
5. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". Delete "It is important to note that".
6. **Trailing clauses that add no fact.** "going forward", "at this point", "when all is said and done". Cut them.
7. **Generic conclusions.** "The future looks bright." State specific plans or facts.

## Content

8. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete or expand with real sources.
9. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or delete.
10. **Say what it does, not how it feels.** "the database stays close at hand", "SQL you can read", "types that follow your schema" name a feeling. The fix names the mechanism or a number, such as "`.toSQL()` returns the exact string sent to the database" or "a column rename fails the build". Ask what the sentence tells the reader to do or know, then write that. If the sentence could appear unchanged in another project's docs, cut it.

## Words

11. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, robust, showcase, tapestry (abstract), testament, underscore, vibrant. Replace with plain words.
12. **Puffery.** Words that add emphasis and no information, such as "really", "truly", "matters", "worth noting", "carries weight", "quietly". State the fact or cut the sentence. "This change really matters for startup" becomes "The change cuts cold start from 900 ms to 300 ms."
13. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Say "is" or "has".
14. **Prefer the plain word.** "utilize" and "leverage" become "use", "facilitate" becomes "help", "numerous" becomes "many", "in the event that" becomes "if".
15. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or the number. "significantly improves" becomes the measured delta.
16. **Abstract metaphor nouns.** The plainer word is in parentheses. Substrate (base), wedge, wedge in (add), vector (way, method), locus, vantage, nexus, primitive as a noun, harness as a metaphor, surface as in "API surface", bedrock, scaffolding as a metaphor, modality, paradigm, gold-plating (more than the job needs), ratchet as a metaphor (the mechanism's real name, or a limit that only tightens), evacuate for moving code (move out), endgame (the last phase), north star, flywheel.
17. **Invented shorthand.** Don't coin terms or labels the reader has to decode. Use an established technical term when it is the most precise one. "The flag is a soft gate on writes" becomes "The flag makes the server log a warning before each write."
18. **Invented hyphenated adjectives.** Words joined with a hyphen to sound compact. "a fail-loud parser" becomes "a parser that exits on the first error". Compounds already in common use, such as "well-known", are fine.
19. **Synonym cycling.** Protagonist, main character, central figure, hero all in one paragraph. Pick one term and repeat it.

## Sentences

20. **"Not just X, but Y."** State what the thing is. "It's not just a linter, it's a whole workflow" becomes "It lints and formats." A plain correction is fine.
21. **Rule of three.** Don't force ideas into groups of three. Use the natural number.
22. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale. List the topics directly.
23. **Stacked rhetorical questions.** "Is the cache stale? Is the key wrong?" becomes "The cause is unknown. It may be a stale cache or a wrong key."
24. **Count openers.** "Two caveats.", "Three things to know." State the first point.
25. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop clauses.
26. **Active voice.** Catch "is/are/was/were + past participle" and name the actor. "queries are validated" becomes "the compiler validates queries". Passive is fine when the actor is unknown or doesn't matter.
27. **Mannered prose.** Metaphor, analogy, or flourish where a literal phrase exists. This covers aphorisms ("wire it or delete it"), rhetorical fragments for effect, personified code ("the plan holds it"), and figurative verbs ("rides along", "stands on"). "A dial worth turning" becomes "a parameter worth varying". "The queue is like a waiting room" becomes "The queue holds jobs until a worker is free."
28. **Catchy headings and labels.** Slogans and clever names in headings, callouts, and summaries. Describe the content. "Closing the loop" becomes "How review comments update the lint rules".

## Punctuation and formatting

29. **Dashes and middle dots.** No em dashes, en dashes, hyphens used as dashes, or parentheses as a substitute. End the sentence or use a comma. Write ranges with "to". No middle dot as a separator.
30. **Colon overuse.** Colons are fine before a list or example, and as a short label in updates and PRs ("Summary:"). Not as mid-sentence connectors. "The fix is simple: clear the cache" becomes "Clear the cache to fix it."
31. **Boldface overuse.** Don't bold every proper noun or acronym.
32. **Inline-header lists.** The tell is a bold label and colon that restates the line, as in "**Performance:** Performance improved...". Convert those to prose. A bold lead-in that ends in a period, names the item, and is followed by new detail is fine.
33. **Title case headings.** Use sentence case.
34. **Decorative emojis.** Remove from headings and bullets.
35. **Curly quotes.** Use straight quotes.
