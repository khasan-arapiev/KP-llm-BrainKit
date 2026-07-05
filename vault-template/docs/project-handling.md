# Project handling

Routed sub-doc for [[CLAUDE]]. Read this only when working with project pages: writing them, updating them, or filing decisions, post-mortems, or learnings against a project. Not loaded on general vault sessions. See also [[index]] and [[log]].

The companion skill `KP-Setup` scaffolds the project folder layer and creates the matching vault pages. This doc covers what the vault does with them after.

---

## Folder layout

```
wiki/projects/<slug>/
  <slug>-overview.md     The entry point. Stack, status, links. (e.g. acme-app-overview.md)
  core/                  Supporting reference docs, grouped together.
    map.md               Module map, entry points, layering, local dev setup.
    context.md           Domain glossary.
    review.md            Definition of Done.
    status.md            Last session, next up, blockers.
    strategy.md          Positioning, business model (optional, only when relevant).
  plans/                 Forward-looking specs. One file per plan.
    <short-slug>.md      No date prefix in filename (date is in frontmatter `created:`).
  decisions/             ADRs, one file per decision. Filename: `<short-slug>.md`.
  post-mortems/          Post-mortems from KP-BugFix. Filename: `<short-slug>.md`.
  learnings/             Captured learnings. Filename: `<short-slug>.md`.
```

**Why this layout:**
- The overview file keeps the `<slug>-overview.md` name so cross-project wikilinks (e.g. `[[acme-app-overview]]`) resolve uniquely without disambiguation.
- The other root pages move into `core/` with short names (`map.md`, `context.md`, etc.). Within a project, write `[[map]]` and Obsidian resolves to this project's map. For cross-project links, use the slug-prefixed alias (every file has `aliases: [<slug>-<type>]` in frontmatter, e.g. `[[acme-app-map]]` still works).
- Plan / decision / post-mortem / learning files drop the date prefix. The date lives in the frontmatter `created:` field. Filenames stay short: `platform-design.md`, `v1-execution-plan.md`, etc.

`<slug>` is the kebab-case project name (e.g. `recipe-box`, `acme-app`).

**Aliases convention.** Every page inside `core/`, `plans/`, etc. should have an `aliases` frontmatter entry listing both the slug-prefixed name and the short name, so wikilinks resolve from anywhere in the vault:

```yaml
aliases: [acme-app-map, Acme App Map]
```

**Client umbrellas with sub-projects** (one client folder hosting several deliverables):

```
wiki/projects/<client-slug>/
  <client-slug>-overview.md
  core/                                          Client-wide reference docs.
  plans/ decisions/ post-mortems/ learnings/     Client-wide artefacts.
  <subproject-slug>/
    <subproject-slug>-overview.md
    core/                                        Sub-project reference docs.
    plans/ decisions/ post-mortems/ learnings/   Sub-project-scoped artefacts.
```

The client umbrella overview links to each sub-project overview. Sub-projects link back up to the umbrella.

---

## Page types

Nine project-related types extend the schema in `CLAUDE.md`. All carry the standard frontmatter (`title`, `tags`, `created`, `updated`) plus a `project: <slug>` field.

| `type` value | What it is | Where it lives |
|---|---|---|
| `project-overview` | The project's home page. Stack, status, links to the rest. | `projects/<slug>/<slug>-overview.md` |
| `project-map` | Module map, entry points, layering, conventions, local dev. | `projects/<slug>/core/map.md` |
| `project-context` | Domain glossary for the project's vocabulary. | `projects/<slug>/core/context.md` |
| `project-review` | Definition of Done checklist. | `projects/<slug>/core/review.md` |
| `project-status` | Last session, next up, blockers. | `projects/<slug>/core/status.md` |
| `project-strategy` | Positioning, business model, long-term plan (optional). | `projects/<slug>/core/strategy.md` |
| `plan` | One PRD from a KP-Grill session. Date-slug filename. | `projects/<slug>/plans/` |
| `decision` | One ADR. Date-slug filename. | `projects/<slug>/decisions/` |
| `post-mortem` | One post-mortem from KP-BugFix. Date-slug filename. | `projects/<slug>/post-mortems/` |
| `learning` | One captured learning. Date-slug filename. | `projects/<slug>/learnings/` |

---

## Operations

Five operations beyond the vault's core ingest / query / lint. All are project-scoped.

### File a decision (ADR)

Trigger: "file a decision on X", "ADR for Y", "we just decided Z".

Steps:
1. Ask the owner for context if anything is unclear (the decision itself, the alternatives considered, the reasoning).
2. **Amend-fold check (anti-churn).** Before creating a file, check whether this decision amends or supersedes one filed in the same project within the last ~7 days. If it does and the choice is the same evolving one, **edit that ADR** instead: revise its Decision section and append a dated `**Changelog:** YYYY-MM-DD — <what changed and why>` line, rather than spawning d(N+1). A new ADR is for a genuinely distinct choice or when the ~7-day window has passed. This stops rapid supersession chains (three ADRs on one UI choice inside 48 hours is over-filing, not a richer record).
3. Create `projects/<slug>/decisions/<YYYY-MM-DD>-<short-slug>.md` using the **ADR template** below. When an ADR does supersede an older one (outside the fold window), set `supersedes:` on the new page and flip the old page's `status: superseded` in the same edit.
4. Link from `projects/<slug>/overview.md` if the decision is strategic.
5. Update `wiki/log.md`: `## [YYYY-MM-DD] decision | <slug>: <one-line summary>`.

### File a post-mortem

Trigger: "post-mortem the X", "write up what went wrong with Y", "incident review on Z".

Steps:
1. Walk the owner through what happened. If the facts are not clear, ask.
2. Create `projects/<slug>/post-mortems/<YYYY-MM-DD>-<short-slug>.md` using the **post-mortem template** below.
3. If the post-mortem produced a decision (e.g. "never deploy on Fridays"), file that as a separate ADR and cross-link.
4. Update `wiki/log.md`: `## [YYYY-MM-DD] post-mortem | <slug>: <one-line summary>`.

### File a learning

Trigger: "save this learning", "this is worth keeping", "memorize that...".

Steps:
1. Confirm in one line that this is a learning (not a decision and not a post-mortem). Learnings are observations or rules of thumb, not formal choices.
2. Create `projects/<slug>/learnings/<YYYY-MM-DD>-<short-slug>.md` using the **learning template** below.
3. Update `wiki/log.md`: `## [YYYY-MM-DD] learning | <slug>: <one-line summary>`.

### Status vocabulary (canonical)

`status:` on a plan or decision uses one controlled value so the per-project index can sort live work above done work. Use exactly these (the generator ranks them in this order, live first):

- **Plans:** `drafted` → `approved` → `building` → `shipped-to-test` → `shipped` → `superseded`. Also allowed: `living` (a standing reference plan, never "done"), `abandoned`.
- **Decisions (ADRs):** `proposed` → `accepted` → `superseded`.

`shipped-to-test` means built and deployed to test, awaiting verify; it is still live pipeline (do not archive). `shipped` means promoted to prod; archive the plan to `plans/archive/` when it reaches `shipped`/`superseded`/`abandoned`. Anything outside this list is flagged by the scanner as an unknown status; pick the closest canonical value rather than inventing a new one. `phase:` is a free-text field used only on `project-status` pages and is not part of this enum.

### Update project status

Trigger: end of a working session, "update status", "where were we on X".

`status.md` holds **current state, next up, and blockers only**. It never narrates sessions. The per-session record (what shipped, commit hashes, deploy IDs, file lists) is the job of [[log]], not status. The reason: `status.md` is the first thing a project session reads (see [[CLAUDE]] § Session boot), so it must stay small and high-signal. Left unattended it drifts into a diary and every future session pays for it at boot. Trimming it back is part of closing a session, not a separate cleanup.

**The keep-vs-move test.** For every block in status, ask: *"If I delete this, does the next chat lose a fact it needs to act correctly or to avoid a mistake?"*
- **Yes → it stays.** This is forward-facing, load-bearing state: current state (one short paragraph, the latest only), next up, blockers and gates, load-bearing constants (live URLs, the law/contract pointers, cutover constraints), alive open follow-ups, the routing table.
- **No → it moves to [[log]].** This is a backward-facing record: per-session narration, commit hashes, deploy IDs, file-by-file change lists, anything shipped/verified/closed that nothing downstream depends on.

Shipped PRDs and old reviews move to the project's `archive.md` (see [[index]] and the per-folder `archive/` pattern), not the log.

**Three guardrails:**
- **Relocate before delete.** Write the log entry (step 4) *first*, detailed enough that trimming status loses nothing load-bearing. Only then trim status. Never delete narration that has no other home. This move is no-ask (no information is lost), like an ADR status flip.
- **Structural cap (measured in bytes, not lines).** The "Right now" / current-state section is one short paragraph (the latest session). The ceiling is **~8 KB target, ~12 KB hard** (`wc -c status.md`), not a line count: a few mega-bullets pass an 80-line check while blowing the boot token budget, so lines are the wrong unit. Past the hard ceiling the trim is mandatory, not optional, and no single bullet may be a paragraph of build narration (commit hashes, gate logs, how-shipped) — that is always the log's job. A large pending-verify backlog can legitimately sit near the hard ceiling; build narration never can.
- **Keep when unsure.** If a block is ambiguous, leave it in status *and* mirror it to the log. Over-trimming (dropping a live item) is the only failure mode that hurts the next chat, so bias toward keeping it in status while guaranteeing the log copy.

Steps:
1. Write the session's per-day record to `wiki/log.md` first (detailed, newest at top): `## [YYYY-MM-DD] <op> | <slug>: <summary>`. This is the relocate-before-delete invariant.
2. Rewrite the current-state paragraph and the **Next up** section of `projects/<slug>/status.md`; apply the keep-vs-move test to every existing block, moving backward-facing detail out (it is now in the log) and keeping forward-facing state.
3. Add or remove blockers. Confirm the routing table at the top still points to the right pages.
4. Bump `updated:` in the page's frontmatter.

### Refresh project context

Trigger: when the codebase's vocabulary has drifted from `context.md`, when a healthcheck flags the glossary as stale, or "refresh context for X".

Steps:
1. Re-read the project's code, especially recently changed files, looking for terms that contradict or extend the glossary.
2. Update `projects/<slug>/context.md` (terms, definitions, avoid list).
3. Bump `updated:`.
4. If a term change is significant, file a decision for it.

---

## Templates

### Decision (ADR)

```markdown
---
title: <decision title>
type: decision
project: <slug>
tags: [decision, <slug>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: proposed | accepted | superseded
supersedes: <slug-of-prior-decision-if-any>
---

# <decision title>

## Context

What forced this decision. The constraint, the trigger, the pressure.

## Options considered

1. **<option A>.** Pros, cons.
2. **<option B>.** Pros, cons.
3. **<option C>.** Pros, cons.

## Decision

The choice. One paragraph, clear.

## Consequences

What we accept by choosing this. What this rules out.

## See also

- [[projects/<slug>/overview]]
- [[projects/<slug>/decisions/<related-decision>]]
```

### Post-mortem

```markdown
---
title: <incident title>
type: post-mortem
project: <slug>
tags: [post-mortem, <slug>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
severity: low | medium | high
---

# <incident title>

## What happened

The facts. No interpretation. Timeline if relevant.

## Root cause

The real reason, not the symptom. Five-whys if needed.

## What we tried

The fixes attempted in order, with what worked and what did not.

## Resolution

How it ended. What is in place now.

## What to do differently

Concrete actions, not platitudes. If a rule emerged, file it as a decision.

## See also

- [[projects/<slug>/overview]]
- [[projects/<slug>/decisions/<related-decision>]]
```

### Learning

```markdown
---
title: <one-line learning>
type: learning
project: <slug>
tags: [learning, <slug>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# <one-line learning>

## What

The observation or rule, in plain English.

## Why it matters

The cost of not knowing this. What it changes about how you work.

## How to apply

When and where this kicks in.

## See also

- [[projects/<slug>/overview]]
```

---

## Healthcheck handoff

The KP-Setup skill's `KP healthcheck` reads the project's vault pages and flags:

- Missing required pages (overview, map, context, review, status).
- Pages with `updated` older than 90 days.
- Wikilinks in project pages that do not resolve.
- The project not being listed in `wiki/index.md` under `## Projects`.

When KP-Setup surfaces these, the agent applies the fix using this doc's operations (write the missing page, refresh context, update status, etc.). Only after the owner approves the healthcheck plan.

---

## What this doc does not cover

- The project folder itself (code structure, the thin `CLAUDE.md` router, `.gitignore`, README). That is the KP-Setup skill's job.
- Cross-project syntheses. Those use the vault's normal `synthesis` page type, not a project-scoped page.
- Personal or business knowledge that is not tied to one project. That stays in normal entity, concept, or synthesis pages at `wiki/`.

If a thing belongs to one project, it lives under `wiki/projects/<slug>/`. If a thing spans projects or stands alone, it lives in the main `wiki/` tree.
