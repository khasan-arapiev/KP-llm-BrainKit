---
name: KP-BugFix
description: >
  Disciplined bug-fix loop. Six phases: reproduce, minimise, hypothesise,
  instrument, fix, regression-check. Stops shortcuts. Forces a real
  understanding of the root cause before any code change. When the fix
  lands, files a post-mortem to the Obsidian Brain vault at
  wiki/projects/<slug>/post-mortems/.
  Trigger on: "KP-BugFix", "KP-bugfix", "bug fix", "fix this bug",
  "this is broken", "this doesn't work", "doesn't work", "isn't working",
  "not working", "failing", "throwing", "throws an error", "errors out",
  "exception", "regression", "stuck on this bug", "weird issue",
  "something is wrong", "help me debug", "debug this", "diagnose this",
  "investigate this", "figure out why", "this is slow", "performance is bad",
  "is laggy", "takes forever", "memory leak", "slow query", "running slow",
  "high CPU", "high memory".
license: MIT
---

# KP-BugFix

A disciplined six-phase loop for fixing real bugs. The cost of guessing is high. The cost of slowing down for ten minutes is low. This skill enforces that trade.

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

## When to use

Anything broken. A failing endpoint, a wrong output, a flaky test, a crash, a regression. Anything where the symptom is observable but the cause is not yet known.

## When NOT to use

- The cause is already known and the fix is obvious. Just fix it.
- The problem is "I do not understand this code". Use `KP-Grill` or just ask.
- The problem is "I want to add a feature". Use `KP-Grill` then build.
- The problem is "audit this project". Use `KP-Setup healthcheck`.

## The six phases

Do them in order. Do not skip. If a phase fails, do not move on, fix that phase first.

### Phase 1: Reproduce

You cannot fix what you cannot trigger.

- Ask the owner for exact reproduction steps if not already clear.
- Run the failing command, hit the failing endpoint, open the failing page.
- Observe the failure with your own eyes (or read the log of one).
- Write down the exact symptom: the error message, the wrong output, the stack trace.

If the bug does not reproduce, stop. Ask:
- "I cannot reproduce. Can you give me the exact input or steps?"
- "Does this happen every time or sometimes?"
- "What was different the last time it worked?"

Never proceed past Phase 1 without a repro.

**Exit clause.** If after 3 reasonable attempts you still cannot reproduce, stop the skill. Do not guess at a fix. File a short post-mortem at `wiki/projects/<slug>/post-mortems/<YYYY-MM-DD>-cannot-reproduce-<short-slug>.md` with `severity: low`, capturing the failed attempts and what is still missing. Ask the owner for more context or a different repro path. End the skill cleanly.

### Phase 2: Minimise

A 500-line case with five moving parts hides the cause. Strip away anything that does not matter.

- Cut inputs, dependencies, and surrounding code until removing one more piece makes the bug disappear.
- The remaining case is the minimum failing case. That is what you debug.

### Phase 3: Hypothesise

State the most likely root cause in one sentence. Then name competing hypotheses.

- "Most likely: the regex is not handling empty strings."
- "Also possible: the upstream API returned null and we did not check."
- "Also possible: a race between A and B."

Do not commit to one hypothesis yet. Listing the field stops you from tunnel-visioning.

### Phase 4: Instrument

Verify the hypothesis with evidence, not vibes.

- Add prints, logs, or breakpoints to narrow the scope.
- Read the actual values at the point of failure.
- Confirm which hypothesis fits the evidence. Rule out the rest.

If no hypothesis fits, go back to Phase 3. Generate new ones. Do not guess at a fix.

### Phase 5: Fix

Make the minimum change that addresses the confirmed cause.

- Trace every line of the change directly to the root cause.
- Do not refactor adjacent code "while you are here".
- Do not add defensive code for hypothetical other bugs.
- Do not silence the symptom (try/catch swallowing the error) without addressing the cause.
- **Remove only the instrumentation added during THIS run.** Every print, log line, breakpoint, debug variable, and temp file added during Phase 4 must come out. Pre-existing logs and instrumentation in the codebase are not yours to touch unless they are themselves the bug. If a log line you added is genuinely worth keeping in production, promote it to a proper logger call deliberately. Otherwise delete it.

### Phase 6: Regression-check

A fix is not done until you have confirmed it sticks.

- Run the minimum failing case from Phase 2. It should now pass.
- Run any related tests, pages, or flows that could share the cause.
- If a test suite exists, run it. If not, manually walk one or two adjacent paths to make sure the fix did not break them.

If anything regressed, return to Phase 3 with the new symptom.

## Output

When the fix is confirmed, file a post-mortem to the vault.

Location: `<vault>/wiki/projects/<slug>/post-mortems/<YYYY-MM-DD>-<short-slug>.md`

Use the post-mortem template defined in `<vault>/docs/project-handling.md`. Fill in:
- What happened (the symptom).
- Root cause (the real reason, not the symptom).
- What we tried (in order).
- Resolution (the fix that worked).
- What to do differently (concrete actions, not platitudes).

Also:
- Update `wiki/log.md`: append `## [YYYY-MM-DD] bugfix | <slug>: <one-line summary>`.
- If a rule emerged from the post-mortem (e.g. "always check upstream API for null"), file it as a separate ADR or learning page.

## Final report back

After the post-mortem is filed, tell the owner in chat:
- The root cause in one sentence.
- The fix in one sentence.
- The path to the post-mortem.
- Any ADR or learning created.

## House style

- Plain English. Short. No em or en dashes.
- Honest. If a phase was skipped or a check failed, say so plainly.
- Never claim "fixed" without running Phase 6.
- Be critical. If the root cause exposes a deeper design problem, surface it as a candidate ADR, do not silently work around it.

## What this skill never does

- It does not propose fixes before Phase 4 (no evidence yet).
- It does not skip Phase 6 ever. Untested fixes are not fixes.
- It does not run on "I want to add X". That is grilling work, not debugging.
- It does not edit unrelated code as a side effect.

## Trigger precedence

- **KP-BugFix vs KP-Grill.** Requires an observable failure to fire. Phrases like "this is broken", "throwing an error", "doesn't work", "is slow" win for BugFix. Forward-looking phrases ("let's plan how we should handle errors") defer to Grill. If both verbs appear in the same sentence ("the deploy script doesn't work, let's plan a fix"), ask: "Are we diagnosing the broken script now, or planning a redesign?" Then run the chosen skill.
- **KP-BugFix vs KP-Setup.** Never overlaps in practice. BugFix runs on existing code; Setup scaffolds new folders.

## Core principles

1. **Repro or stop.** No repro, no fix.
2. **Evidence before action.** Phase 4 before Phase 5, always.
3. **Trace every change.** Every edit lines up with the confirmed root cause.
4. **Verify before claiming.** Phase 6 is non-negotiable.
5. **Capture the lesson.** A post-mortem closes the loop. Without it, the same bug returns.
6. **Leave it clean.** All instrumentation, scratch files, test data, and workshop artefacts created during this skill must be removed before claiming done. The codebase must look like only the fix was applied, nothing else.
