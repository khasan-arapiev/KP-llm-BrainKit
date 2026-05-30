---
name: code-cowork
description: Pair-programming mode for building features clean from the first keystroke. Auto-invokes when building a feature in a code project: plans non-trivial work first (KP-Grill or brainstorming), does a quick architecture pass against existing ADRs and patterns, then builds with TDD and the owner's house style held proactively. Trigger on "code-cowork", "build this feature", "build the X", "implement X", "implement the Y", "add Y", "let's build", "let's code this", "create a feature", "work on this feature", "develop X". Skips trivial one-line edits. Does NOT lint the vault or update index/log — that is wrap-up's job.
license: MIT
metadata:
  version: "1.0"
allowed-tools: Bash(gh:*) Bash(glab:*) Bash(git:*) Bash(p4:*) Bash(npm:*) Bash(pnpm:*) Bash(yarn:*) Bash(pytest:*) Bash(go:*) Bash(cargo:*) Read Write Edit Glob Grep
---

# code-cowork

Build-mode skill. The owner wants a feature built and wants it clean from the start. This skill is the conductor: it plans first, architects against existing structure, then writes code to a high standard proactively so the wrap-up ritual has nothing to clean up.

It composes other skills:

- [[KP-Grill]] — PRD-style grilling for non-trivial features (when scoping is needed).
- [[superpowers:brainstorming]] — design exploration for non-trivial features (when scope is clear but approach is not).
- [[superpowers:test-driven-development]] — when a test can be written for the change.
- [[superpowers:verification-before-completion]] — before claiming a step is done.

The code-cowork skill is the conductor. It does NOT reimplement what those skills do — it invokes them in order and threads them together.

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

---

## When to run

Auto-invoke when the owner asks to build a feature in a code project. Typical phrasings:

- "/code-cowork" or "let's code-cowork this"
- "build the auth flow"
- "implement the export feature"
- "add a settings page"

## When NOT to run

- Vault-only edits (no code touched). Just edit.
- Bug fixes. Use [[KP-BugFix]].
- New project scaffolding. Use [[KP-Setup]].
- End-of-session cleanup. Use [[wrap-up]].
- Tiny one-line changes (typo, rename, single import). Skip the ceremony and just make the change.

---

## Pipeline

Run these phases in order. Each phase produces a status (ok / warn / blocked). Roll the worst status forward so the closing report reflects reality.

### Phase 0 — Locate the project and load context

Identify which project the feature belongs to. Sources of truth, in order:

1. The owner's request (explicit project name or path).
2. The current working directory.
3. `git rev-parse --show-toplevel` to find the repo root.
4. If the owner keeps code under `<vault>/production/<slug>/`, match the repo root to a slug there.

Then load context, in this order, and stop reading once you have enough to plan:

1. The project's `CLAUDE.md` (router).
2. The project's vault pages: `wiki/projects/<slug>/<slug>-overview.md`, `core/map.md`, `core/context.md`, plus the most recent `post-mortems/`, `learnings/`, and `decisions/` (ADRs).
3. In-repo docs: `CONTEXT.md`, `docs/adr/`, README.
4. The files the feature is likely to touch (Glob + Read on the most relevant 3-5).

Output a 3-5 line context summary back to the owner so they can correct any wrong assumption before any planning starts.

### Phase 1 — Plan (non-trivial only)

Classify the work:

- **Trivial** — one-line change, obvious rename, single import add, typo, formatting. Skip planning.
- **Non-trivial** — anything else. Plan first.

For non-trivial, pick one based on what is missing:

- **Scope/requirements unclear** → invoke [[KP-Grill]]. One sharp question per turn, capped at 10. Output is a PRD page in `wiki/projects/<slug>/plans/`.
- **Scope clear, approach/design unclear** → invoke [[superpowers:brainstorming]] to explore options before committing.
- **Both already nailed in the request** → skip to Phase 2, but restate the goal and success criteria in your own words and get a yes before proceeding.

Never skip planning to "just get started". The messes wrap-up cleans up are usually planning failures.

### Phase 1.5 — Trace the runtime read path (mandatory for any config / schema / seed change)

Applies to every project, not just one. If the feature touches a config file, schema, seed file, fixture, template, default settings file, or any "data shape" file, do this BEFORE Phase 2:

1. Grep for the file across the repo. Identify every consumer.
2. If the only consumers are seeders, migrations, `npm run seed`-style scripts, or test fixtures, the file is a **one-shot input**. Edits to it will NOT reach existing rows, tenants, caches, or installed clients.
3. Find the runtime loader (e.g. `*-loader.ts`, `config.ts`, `settings.ts`, anything the running app actually calls at request time). Read it. Confirm where the live data lives (DB row, Redis cache, env, generated artifact, on-disk state).
4. If the runtime path goes through anything other than the file itself, the plan MUST include a backfill step: a migration, re-seed script, admin re-import flow, or a runtime fallback that handles old-shape data gracefully.
5. State this explicitly in the plan: "Existing rows pick this change up via X." If you cannot write that sentence, the plan is incomplete.

Why: edits to seed/template files silently no-op for existing data. Typecheck and unit tests do not catch it because they do not exercise the runtime data-load path. The only honest verification is hitting the deployed environment with real data — which means Phase 4 must include a manual UI/API check, not just CI green.

### Phase 2 — Architect the change (report-only)

Before writing any code, run a quick architecture pass yourself. This is a check, not a redesign.

1. Re-read the project's filed ADRs (`wiki/projects/<slug>/decisions/`) and `core/map.md`. Note the module boundaries, layering rules, and conventions already in place.
2. Sketch how the feature fits: which modules it touches, which boundary it should sit behind, what it must not break.
3. Surface any conflicts with existing ADRs, patterns, or module boundaries in 3-5 bullets to the owner.
4. If the cleanest path conflicts with what was requested:
   - Name the trade-off in one or two sentences.
   - Recommend the cleaner path.
   - Wait for the owner to choose. Do not silently "improve" what was asked.
5. If no conflicts → state "architecture pass clean, proceeding" and move on.

If there are no ADRs or map yet (early project), say so and proceed on the conventions visible in the code.

### Phase 3 — Build to a high standard

Hold the quality bar proactively. The point of this phase is that a later review finds nothing.

**Process:**

1. When a test can be written before the code, use [[superpowers:test-driven-development]]. When it cannot (UI, exploratory spike, integration glue), say so explicitly and skip TDD — do not fake it.
2. After each meaningful unit of work, invoke [[superpowers:verification-before-completion]] before claiming that unit works. Run the actual tests/lint/typecheck. Evidence before assertions.

**Code standards (apply proactively, not retroactively):**

- Match the project's existing conventions: naming, structure, file organization, framework idioms. Read neighbors before inventing.
- Reuse before inventing. If an existing button, modal, hook, or module already does the job, use it. If it almost does, extend it so it serves both cases. Only create a new one when nothing existing fits, and say why in the commit.
- House style: no em or en dashes anywhere; plain English; short sentences; no filler.
- **No comments of any kind.** Names and types carry the meaning. If code needs a comment to be understood, rename or restructure instead. Strip comments from lines you edit.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code. Validate only at system boundaries (user input, external APIs).
- Don't add features, refactor, or introduce abstractions beyond what the task requires. Three similar lines beats a wrong abstraction. Don't design for hypothetical futures.
- Don't write backwards-compat shims, unused `_var` renames, `// removed` comments, or re-exports for code that's truly gone. Delete cleanly.
- Security: actively avoid OWASP top 10 (injection, XSS, SSRF, auth bypass, etc.). If you wrote insecure code, fix it immediately.
- No feature flags or compat layers when the code can just change.

**Discipline carried in from the vault CLAUDE.md:**

- Never guess. If a value, API shape, or path is unknown, read it, search for it, or ask.
- State assumptions explicitly. If multiple interpretations exist, surface them.
- Be critical. If the request leads to a fragile or wrong design, flag it before coding it.
- Honesty over comfort. Never claim a step works unless it was actually run and the result was seen.

### Phase 4 — Commit and self-review

Once the feature is functionally complete and verification passed:

1. Ensure all working changes are committed on a feature branch (not main). Commit message follows the project's conventional style.
2. Do a final self-review of the diff against the Phase 3 standards: dead code, stray comments, anything that drifts from existing conventions, anything untested that should be tested.
3. If the project has a remote and the owner wants a PR, push the branch and open a **draft PR** (`gh pr create --draft` or `glab mr create --draft`). Draft signals work-in-progress.

**Never** force-push. **Never** skip hooks (`--no-verify`, `--no-gpg-sign`, etc.) unless the owner explicitly asks.

### Phase 5 — Hand-off report

Print a single block to the conversation. Format:

```
=== code-cowork complete ===

Project: <slug>
Feature: <one-line description>

Planning:
  - <KP-Grill PRD path / brainstorming summary / "skipped, trivial">

Architecture:
  - <"clean" or "1 conflict surfaced — see above">

Build:
  - <N> files changed, <N> tests added
  - TDD: <yes / skipped because <reason>>
  - Verification: <commands run + results>

Open items:
  - <architectural concern from Phase 2 needing a decision>
  - <anything blocked or deferred>
```

Then stop. Do NOT lint the vault. Do NOT update `wiki/index.md` or `wiki/log.md`. Do NOT print "safe to close". Those are [[wrap-up]]'s job. This skill exits cleanly so the owner can either keep working or run `/wrap-up` when done for the session.

---

## Discipline rules

**A. Plan before code for non-trivial.**
Skipping planning to "just get started" is the source of most of the messes wrap-up cleans up. The trivial/non-trivial test is honest: if you have to think about whether it's trivial, it isn't.

**B. Honesty over comfort.**
Never claim a test passes or a build is green without evidence from the actual command output. If a step was skipped, say which and why. "I don't know" is a valid answer.

**C. No drive-by changes.**
Touch only what the feature requires, plus anything the feature's edits break (a renamed symbol's call sites). Surface unrelated issues in the hand-off report. Do not silently "improve" unrelated code.

**D. Reversibility.**
Feature branch + draft PR pattern. No direct pushes to main. No force-push. No `--no-verify`. If a destructive action would be required, stop and ask.

---

## Verify checkpoints

Before printing the hand-off report, confirm each. If any fail, the report says so plainly with the failing item.

1. Phase 0 produced a project slug and a context summary that the owner did not contradict.
2. Phase 1 either ran a plan (PRD/brainstorm) or correctly classified as trivial.
3. Phase 2 either ran clean or surfaced conflicts that the owner resolved before Phase 3.
4. Phase 3 verification commands were actually executed and their output was seen.
5. No vault edits were made (this skill does not touch the vault).

If a checkpoint fails, say so. Do not claim the feature is done.

---

## What this skill is NOT for

- End-of-session cleanup. Use [[wrap-up]].
- Bug fixes. Use [[KP-BugFix]].
- Project scaffolding. Use [[KP-Setup]].
- Vault edits. Just edit.

This is the build ritual. Run it once per feature.
