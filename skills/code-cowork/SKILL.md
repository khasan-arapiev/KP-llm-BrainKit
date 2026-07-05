---
name: code-cowork
description: Pair-programming mode for building features clean from the first keystroke. Front-loads the quality bar that wrap-up enforces retroactively. Plans non-trivial work first (KP-Grill or brainstorming), does a quick architecture pass against existing ADRs and patterns, builds inline with TDD and the house style held proactively, then runs two gates at the end of the feature, the deterministic fallow audit and a semantic self-review, fixing what they find. Use when the owner invokes /code-cowork, or says "build this feature", "implement X", "add Y" in a coding project and explicitly wants to work with this skill. Does NOT lint the vault or update index/log, that is wrap-up's job.
license: MIT
metadata:
  version: "1.5"
allowed-tools: Bash(gh:*), Bash(glab:*), Bash(git:*), Bash(p4:*), Bash(npm:*), Bash(pnpm:*), Bash(yarn:*), Bash(npx:*), Bash(pytest:*), Bash(go:*), Bash(cargo:*), Bash(fallow:*), Bash(graphify:*), Read, Write, Edit, Glob, Grep, TodoWrite
---

# code-cowork

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that
file is missing, ask the owner where their Brain vault lives and offer to create the
config. Throughout this skill, `<vault>` means that resolved path.

Build-mode skill. The owner wants a feature built and wants it clean from the start. This skill is the conductor: it plans first, architects against existing structure, writes code to a high quality bar proactively, then runs a deterministic `fallow` audit gate at the end so the wrap-up ritual has nothing to clean up.

It composes other skills and two CLI tools:

- [[KP-Grill]] — PRD-style grilling for non-trivial features (when scoping is needed).
- [[superpowers:brainstorming]] — design exploration for non-trivial features (when scope is clear but approach is not).
- [[improve-codebase-architecture]] — report-only architecture pass before coding.
- [[superpowers:test-driven-development]] — when a test can be written for the change.
- [[superpowers:verification-before-completion]] — before claiming a step is done.
- `graphify` — code knowledge graph. Queried for blast radius, consumer lists, and dependency paths in Phases 0, 1.5, and 2. AST-only and free; built once per project and kept fresh by a post-commit hook. Install: `uv tool install graphifyy` (or `pip install graphifyy`).
- `fallow` — deterministic JS/TS audit gate (dead code, complexity, duplication, cycles) run on the changed files at the end of the feature. Install: `npm install -g fallow`.

This skill builds inline. The main agent writes the code and reviews it in this conversation; no implementer or reviewer subagent is spawned.

The code-cowork skill is the conductor. It does NOT reimplement what those skills do — it invokes them in order and threads them together.

---

## When to run

The owner triggers this when they want to build a feature with quality enforced from the start. Typical phrasings:

- "/code-cowork"
- "/code-cowork build the auth flow"
- "build this feature with code-cowork"
- "let's code-cowork this"

Do NOT auto-fire on every code edit. The user opts in explicitly.

## When NOT to run

- Vault-only edits (no code touched). Just edit.
- Bug fixes. Use [[KP-BugFix]].
- New project scaffolding. Use [[KP-Setup]].
- End-of-session cleanup. Use [[wrap-up]].
- Tiny one-line changes (typo, rename, single import). Skip the ceremony and just make the change.

---

## Pipeline

Run these phases in order. Each phase produces a status (ok / warn / blocked). Roll the worst status forward so the closing report reflects reality.

At pipeline start, create a TodoWrite checklist with one item per phase (0, 1, 1.5 if applicable, 2, 3, 3.5, 3.6, 4, 5). Mark each as it completes. This is what stops a gate from being silently dropped when the session runs long.

### Phase 0 — Locate the project and load context

Identify which project the feature belongs to. Sources of truth, in order:

1. The user's request (explicit project name or path).
2. The current working directory.
3. `git rev-parse --show-toplevel` to find the repo root.
4. Match repo root to a `production/<slug>/` under `<vault>\production\`.

Then load context, in this order, and stop reading once you have enough to plan:

1. The project's `CLAUDE.md` (router).
2. The project's vault pages: `wiki/projects/<slug>/<slug>-overview.md` and `core/status.md` first (current state, next up, blockers), then `core/map.md`, `core/context.md`, and the most recent `decisions/` (ADRs), `post-mortems/`, `learnings/` only as the task reaches them.
3. Lessons: scan the Lessons section of `wiki/index.md` and open any lesson whose one-liner or `applies-to:` matches this project or stack (the CLAUDE.md boot rule; documented mistakes must actually load).
4. In-repo docs: `CONTEXT.md`, `docs/adr/`, README.
5. The files the feature is likely to touch (Glob + Read on the most relevant 3-5).

**graphify graph.** Check for `graphify-out/graph.json` at the repo root.

- **Present:** use it as the structure index for the rest of this run. Before cold-reading files in step 4, run `graphify explain "<file>"` on the most relevant ones to see their importers and consumers, and prefer `graphify query` / `path` / `affected` over blind Grep for any "what connects to what" question. The graph's god nodes are a fast read on where the load-bearing code is.
- **Absent:** build it once, AST-only and free, then continue. Do not block on this and do not run the semantic pass.
  1. Write a `.graphifyignore` at the repo root: copy the repo's root `.gitignore`, then append doc/media globs so the corpus is code-only (`*.md`, `*.mdx`, `*.txt`, `*.rst`, `*.pdf`, `*.png`, `*.jpg`, `*.jpeg`, `*.gif`, `*.svg`, `*.mp4`, `*.mov`, `*.mp3`, `*.wav`). graphify reads `.graphifyignore` in preference to `.gitignore`, so it must also carry the heavy-dir excludes (`node_modules/`, `dist/`, `build/`, etc.) or they come back in.
  2. `graphify extract . --no-cluster` — local AST only, no API key, no token cost. A code-only corpus needs no LLM.
  3. `graphify hook install` — post-commit hook that re-runs AST extraction on changed files after every commit, keeping the graph fresh for free.
  4. Add `graphify-out/` to the repo's `.gitignore` if it is not already there (generated artifact, not source).
- If `graphify` is not on PATH (`graphify --version` fails), log a warn `graphify not installed` and fall back to Grep for the whole run. Do not hard-fail.

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

1. Identify every consumer. If `graphify-out/graph.json` exists, run `graphify affected "<file>"` to list everything that depends on it (reverse traversal, accepts the filename and filters by relation/depth), then confirm with a Grep. If `affected` errors, fall back to `graphify explain "<node-id>"`, whose `<--` reverse edges are the same blast radius (node id is `{parent_dir}_{filename_stem}`). Otherwise Grep for the file across the repo. The graph catches consumers a filename Grep misses (re-exports, barrel files, aliased imports).
2. If the only consumers are seeders, migrations, `npm run seed`-style scripts, or test fixtures, the file is a **one-shot input**. Edits to it will NOT reach existing rows, tenants, caches, or installed clients.
3. Find the runtime loader (e.g. `*-loader.ts`, `config.ts`, `settings.ts`, anything the running app actually calls at request time). Read it. Confirm where the live data lives (DB row, Redis cache, env, generated artifact, on-disk state). If the graph exists, `graphify path "<file>" "<suspected-loader>"` surfaces the dependency chain from the file to the request-time loader.
4. If the runtime path goes through anything other than the file itself, the plan MUST include a backfill step: a migration, re-seed script, admin re-import flow, or a runtime fallback that handles old-shape data gracefully.
5. State this explicitly in the plan: "Existing rows pick this change up via X." If you cannot write that sentence, the plan is incomplete.

Why: edits to seed/template files silently no-op for existing data. Typecheck and unit tests do not catch it because they do not exercise the runtime data-load path. The only honest verification is hitting the deployed environment with real data — which means Phase 4 must include a manual UI/API check on test, not just CI green.

### Phase 2 — Architect the change (report-only)

Before writing any code:

1. If `graphify-out/graph.json` exists, run `graphify affected "<primary-file>"` first to read the change's blast radius, and feed that set as the scope for the architecture pass instead of guessing the boundary.
2. Invoke [[improve-codebase-architecture]] in **report-only mode** — no interactive grilling loop. Scope it to the area the feature will touch.
3. Surface any conflicts with existing ADRs, patterns, or module boundaries in 3-5 bullets to the owner.
4. If the cleanest path conflicts with what was requested:
   - Name the trade-off in one or two sentences.
   - Recommend the cleaner path.
   - Wait for the owner to choose. Do not silently "improve" what was asked.
5. If no conflicts → state "architecture pass clean, proceeding" and move on.

This phase is fast. It is a check, not a redesign. If `improve-codebase-architecture` cannot run (unsupported language, no source files yet) → log a warn and proceed.

### Phase 3 — Build to the quality bar

Hold the quality bar proactively. The point of this phase is that the fallow gate (Phase 3.5) and any later review find nothing.

**Build inline.** The main agent writes the code in this conversation, pair-programming with the owner. Design emerges as you go, UI taste calls get made together, and the next edit can depend on their reaction. Hold the bar yourself as you write: match conventions, reuse before inventing, no comments, so the gates downstream find nothing. Do not spawn an implementer subagent for the build.

**Process:**

1. When a test can be written before the code, use [[superpowers:test-driven-development]]. When it cannot (UI, exploratory spike, integration glue), say so explicitly and skip TDD — do not fake it.
2. After each meaningful unit of work, invoke [[superpowers:verification-before-completion]] before claiming that unit works. Run the actual tests/lint/typecheck. Evidence before assertions.

**Conditional skill routing (invoke when the trigger fits, skip silently otherwise):**

- **UI-heavy feature** (new pages, components, visual work) → invoke [[frontend-design:frontend-design]] for the build itself, so the output has real design quality instead of generic AI aesthetics.
- **The diff touches auth, sessions, payments, file upload, or any surface that parses external input** → run [[security-review]] on the change before the Phase 3.5 gate. The prose rule "avoid OWASP top 10" is a reminder; this is the check.
- **TDD was skipped** (UI, integration glue) → verification must be behavioral, not static: use [[verify]] or [[run]] to launch the app and observe the change actually working. Typecheck green on an untested code path is not evidence.

**Code standards (apply proactively, not retroactively):**

- Match the project's existing conventions: naming, structure, file organization, framework idioms. Read neighbors before inventing.
- Reuse before inventing. If an existing button, modal, hook, or module already does the job, use it. If it almost does, extend it so it serves both cases. Only create a new one when nothing existing fits, and say why in the commit.
- Climb the ladder before writing: reuse what's in the repo, then the standard library, then a native platform feature, then an already-installed dependency, then one line, then minimum code. Stop at the first rung that works. Never add a dependency for what the platform or a few lines already do. A native control (`<input type="date">`), CSS over JS, or a DB constraint over app code beats pulling a library.
- the house style: no em or en dashes anywhere; plain English; short sentences; no filler.
- **Icons are SVG, never glyphs.** In UI, never use unicode symbol characters or emoji as icons: arrows, chevrons, checkmarks, crosses, stars, spinners, hamburger menus, and the like. Use SVG: the project's existing icon set or icon component if it has one, otherwise inline SVG. Glyphs render inconsistently across fonts and platforms and cannot be sized, stroked, or coloured precisely; SVG is crisp, controllable, and accessible. This is about UI iconography, not legitimate text content.
- **No comments of any kind.** Names and types carry the meaning. If code needs a comment to be understood, rename or restructure instead. Strip comments from lines you edit.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code. Validate only at system boundaries (user input, external APIs).
- Don't add features, refactor, or introduce abstractions beyond what the task requires. Three similar lines beats a wrong abstraction. Don't design for hypothetical futures. Two equivalent options, same size? Take the one that's correct on edge cases. Fewer lines never means the flimsier algorithm.
- Don't write backwards-compat shims, unused `_var` renames, `// removed` comments, or re-exports for code that's truly gone. Delete cleanly.
- Security: actively avoid OWASP top 10 (injection, XSS, SSRF, auth bypass, etc.). If you wrote insecure code, fix it immediately.
- No feature flags or compat layers when the code can just change.
- **Broken windows.** Be picky about everything you can see while building: UI detail (spacing, alignment, states, pixel-level polish), lint warnings, failing or flaky tests. Inside the task's scope, fix it now, even if it was already broken. Outside the task's scope, flag it with a one-line offer to fix. Never silently drive-by fix, and never walk past it unmentioned.

**Discipline carried in from the vault CLAUDE.md:**

- Never guess. If a value, API shape, or path is unknown, read it, search for it, or ask.
- Propose, do not interrogate. Decide what you can reason out, state the choice and its assumption in one line; ask only at genuine forks (irreversible, expensive, taste).
- Be critical. If the request leads to a fragile or wrong design, flag it before coding it.
- Honesty over comfort. Never claim a step works unless it was actually run and the result was seen.

### Phase 3.5 — fallow audit gate (JS/TS projects)

This is the deterministic quality gate. It runs locally, needs no remote and no external service, so it works on every project today. fallow is what catches the dead code, complexity, duplication, and architecture cycles before the change leaves your machine.

**Applicability.** Runs only on JavaScript/TypeScript projects (a `package.json` or `.ts`/`.js` sources). For other stacks (Python, Go, Rust), log a warn `fallow N/A (not a JS/TS project)` and skip to Phase 4. If `fallow` is not on PATH (`fallow --version` fails), log a warn `fallow not installed` and skip — do not hard-fail the feature.

Run this once the feature is functionally complete and Phase 3 verification passed, **before committing**:

1. `fallow audit --format json` — auto-detects the base branch, scopes to the changed files, returns a verdict (`pass` / `warn` / `fail`). By default only findings the changeset **introduced** count toward the verdict; inherited debt is reported with `introduced: false` and does not block. This matches rule C (no drive-by changes) — do not switch to `--gate all`.
2. Verdict `pass` → gate clean. Proceed to Phase 4.
3. Verdict `warn` / `fail`:
   a. Clear the safe auto-fixable findings (unused exports, dead dependencies, dead enum members). **In a monorepo, NEVER run `fallow fix`** — it acts repo-wide on inherited findings, not just the changeset, and can remove real devDependencies; clear these findings by hand, scoped to the files this session touched. Only in a single-package repo may you run `fallow fix --yes --no-create-config`, and afterwards `git status` + diff every `package.json` and revert anything outside the session's scope before continuing. Report exactly what was removed either way.
   b. Re-run `fallow audit`. Findings that remain (complexity / CRAP hotspots, code duplication, architecture cycles) are **not** auto-fixable. For each one, do the right thing:
      - **Refactor it properly** — extract the duplicated block, split the over-complex function, break the cycle. This is rule E: fix it now, not "later".
      - **Only if** a finding is a genuine false positive or a deliberate, defensible choice, accept it and justify it in one line in the hand-off report.
   c. Re-run audit after each round. Loop until the verdict is `pass`, or the only remaining findings are accepted-and-justified.
4. **Never suppress to go green.** Do not add a baseline, an ignore comment, or a threshold bump to force a `pass`. A suppressed real finding is the easy path wearing the right path's clothes. The gate is honest or it is worthless.
5. **Hard stop:** the same finding survives repeated fix attempts, or clearing it needs a design decision you cannot make alone. Stop, record the finding, surface it in the report. Do not fake the verdict.

### Phase 3.6 — Semantic self-review gate (mandatory for non-trivial, all stacks)

fallow is mechanical; this gate is semantic. It catches what no linter can: reinvented modules, ADR conflicts, wrong abstractions, convention drift, missed call sites, security holes. It runs on every project regardless of language or remote.

Review your own change with fresh, adversarial eyes. Do not skim. Re-read the diff as if a reviewer were trying to reject it.

1. Establish the diff scope (branch + base, or "working tree") and re-read every changed hunk against the project's ADRs, conventions, and existing modules. Use the graphify graph (`graphify affected`, `graphify path`) to confirm you did not miss a call site or reinvent something that already exists.
2. Check each axis explicitly: reinvented modules (did an existing util/hook/component already do this?), reinvented stdlib or a dependency doing what the platform already does (rung 3-5 of the ladder), ADR conflicts, wrong or premature abstractions, convention drift, missed call sites, and the OWASP surfaces from Phase 3. Write down a findings list with a verdict (`ship` / `fix-then-ship` / `rework`).
3. Act on the verdict:
   - **ship** → gate clean, proceed to Phase 4.
   - **fix-then-ship** → fix every CRITICAL and IMPORTANT finding inline. NITS are judgment calls; take the cheap ones. If any fix touched JS/TS code, re-run `fallow audit` once (cheap, deterministic). Then re-read the changed hunks once more to confirm the findings are closed. Max two review rounds; if findings survive round two, hard stop and surface to the owner.
   - **rework** → the approach is wrong. Stop. Present the rationale to the owner with your own read and a recommendation. Do not patch around a wrong shape.
4. **Never argue a finding away to go green.** A finding is closed by a fix, or by a one-line justification in the hand-off report naming why it is a false positive or a deliberate choice. Same honesty bar as the fallow gate.
5. **The honesty trap.** This is your own code, so the pull is to wave it through. Judge it the way an independent reviewer would: against how the system is *intended* to work, not against "it runs". If you find nothing, state what you checked; do not just assert "clean".
6. Skip only for trivial changes (the Phase 1 classification). A skipped gate is logged in the report as `self-review: skipped (trivial)`.

### Phase 4 — Commit and push

Once the fallow gate is clean (or only accepted-and-justified findings remain):

1. Ensure all working changes are committed on a feature branch (not main). Commit message follows the project's conventional style.
2. If the project has a remote:
   - Push the branch.
   - Open a **draft PR** (`gh pr create --draft` or `glab mr create --draft`). The draft is the reviewable artifact.
3. If the project has no remote → log a warn (`no remote, skipping push/PR`). Local commit must still be clean.

**Hard stops** (mirror wrap-up Phase 2): a check failure the agent cannot fix, a push failure (auth, conflicts, protected branch). Stop, log the reason, surface in the closing report.

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

fallow gate:
  - verdict: <pass / pass with accepted findings>
  - auto-fixed: <N unused exports/deps/enum members removed, or none>
  - refactored: <N complexity/dupe/cycle findings fixed by hand, or none>
  - accepted: <finding + one-line justification, per finding, or none>
  - OR: skipped (<not a JS/TS project | fallow not installed>)

Semantic self-review:
  - verdict: <ship / ship after <N> fixes / skipped (trivial)>
  - checked: <axes reviewed — reuse, ADRs, abstractions, call sites, security>
  - fixed: <N CRITICAL, N IMPORTANT findings resolved, or none>
  - accepted: <finding + one-line justification, per finding, or none>

Commit:
  - branch <name>, draft PR #<num> <link>
  - OR: local commit only (no remote)

Open items:
  - <architectural concern from Phase 2 needing a decision>
  - <anything blocked or deferred>
```

Then stop. Do NOT lint the vault. Do NOT update `wiki/index.md` or `wiki/log.md`. Do NOT print "safe to close". Those are [[wrap-up]]'s job. This skill exits cleanly so the user can either keep working or run `/wrap-up` when done for the session.

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

**E. Right path, not easy path.**
Build the correct, complete version of the thing. Never the convenient half. If something the feature touches is already wrong, inefficient, or fragile, it gets fixed now, not logged as "good enough for today, clean up later". Chasing ease today hits harder tomorrow.
- Do NOT propose deferring a needed fix to "a separate phase / next session / a later refactor" as a way to dodge the hard part. Deferral is only legitimate when the deferred work is genuinely independent of the current feature AND shipping without it leaves the product correct, not merely passing. If the product is wrong without it, it is in scope. Say so and do it.
- "It already worked before / the tests are green" is not proof it is right. Wrong-but-passing is still wrong. Judge against how the system is *intended* to work, not against the current behaviour.
- When you catch yourself reaching for "we can do this properly later", stop. That is the lazy path talking. Name the right path, state its real cost honestly, and do it. If the cost genuinely cannot fit the session, say that plainly and let the owner decide, but never dress up the easy path as the sensible one.
- Sequencing risky work into safe steps is fine and encouraged. Sequencing as an excuse to never reach the hard part is not. The end state must be the fully correct system, every time.

**F. Token discipline (never at quality's expense).**
Tokens are saved by working smarter, not by skipping gates or compressing reports into ambiguity.
- Prefer graphify queries over broad Greps and cold file reads for any "what connects to what" question. One graph query replaces a fan-out of searches.
- Read only what the task needs: stop at "enough to plan" in Phase 0, read line ranges not whole files when the file is large, never re-read a file you just edited.
- Do not re-gate what was already gated. A diff that passed fallow + the self-review this session is done; wrap-up must not re-review it.
- Do not bake compression into pipeline reports; gate results must stay unambiguous.

**G. No subagents unless the owner asks.**
This skill runs inline. The main agent does the planning, building, gating, and review itself, in this conversation. Do not spawn subagents (codis, revis, Explore, Plan, general-purpose, or any other) for any phase unless the owner explicitly asks for one. Reasons: the build is a pair-programming loop where the next edit depends on their reaction, and a subagent breaks that loop and hides the work. If a task feels big enough to want a subagent, that is a signal to plan it (Phase 1), not to delegate it away. The composed skills this pipeline invokes ([[KP-Grill]], [[improve-codebase-architecture]], etc.) run inline too.

---

## Verify checkpoints

Before printing the hand-off report, confirm each. If any fail, the report says so plainly with the failing item.

1. Phase 0 produced a project slug and a context summary that the owner did not contradict.
2. Phase 1 either ran a plan (PRD/brainstorm) or correctly classified as trivial.
3. Phase 2 either ran clean or surfaced conflicts that the owner resolved before Phase 3.
4. Phase 3 verification commands were actually executed and their output was seen.
5. Phase 3.5 fallow gate reached a `pass` verdict (or only accepted-and-justified findings remain), or was skipped with a logged reason. No finding was suppressed (baseline / ignore / threshold bump) to force the verdict.
6. Phase 3.6 has a recorded semantic self-review verdict of `ship` (directly or after fixes), or a logged `skipped (trivial)`. No finding was argued away without a written justification.
7. Phase 4 has a clean commit on a feature branch, plus either a draft PR or a logged skip reason (no remote).
8. No vault edits beyond what the composed skills filed by design (a KP-Grill PRD or ADR in `wiki/projects/<slug>/`). No index.md, log.md, or lint edits — those are [[wrap-up]]'s job.

If a checkpoint fails, say so. Do not claim the feature is done.

---

## What this skill is NOT for

- End-of-session cleanup. Use [[wrap-up]].
- Bug fixes. Use [[KP-BugFix]].
- Project scaffolding. Use [[KP-Setup]].
- Vault edits. Just edit.
- One-off PR review. Use [[check-pr]] directly.

This is the build ritual. Run it once per feature.
