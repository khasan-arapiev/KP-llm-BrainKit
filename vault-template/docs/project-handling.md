# Project handling

Routed sub-doc for [[CLAUDE]]. Read this only when working with project pages: writing them, updating them, or filing decisions, post-mortems, or learnings against a project. Not loaded on general vault sessions. See also [[index]] and [[log]].

The companion skill `KP-Setup` scaffolds the project folder layer and creates the matching vault pages. This doc covers what the vault does with them after.

---

## Folder layout

```
wiki/projects/<slug>/
  <slug>-overview.md     The entry point. Stack, status, links. (e.g. my-app-overview.md)
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
- The overview file keeps the `<slug>-overview.md` name so cross-project wikilinks (e.g. `[[my-app-overview]]`) resolve uniquely without disambiguation.
- The other root pages move into `core/` with short names (`map.md`, `context.md`, etc.). Within a project, write `[[map]]` and Obsidian resolves to this project's map. For cross-project links, use the slug-prefixed alias (every file has `aliases: [<slug>-<type>]` in frontmatter, e.g. `[[my-app-map]]` still works).
- Plan / decision / post-mortem / learning files drop the date prefix. The date lives in the frontmatter `created:` field. Filenames stay short: `platform-design.md`, `v1-execution-plan.md`, etc.

`<slug>` is the kebab-case project name (e.g. `my-app`, `example-app`).

**Aliases convention.** Every page inside `core/`, `plans/`, etc. should have an `aliases` frontmatter entry listing both the slug-prefixed name and the short name, so wikilinks resolve from anywhere in the vault:

```yaml
aliases: [my-app-map, My App Map]
```

**Client umbrellas with sub-projects** (e.g. a client hosting studio-tool, ads-landing, sign-off):

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
2. Create `projects/<slug>/decisions/<YYYY-MM-DD>-<short-slug>.md` using the **ADR template** below.
3. Link from `projects/<slug>/overview.md` if the decision is strategic.
4. Update `wiki/log.md`: `## [YYYY-MM-DD] decision | <slug>: <one-line summary>`.

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

### Update project status

Trigger: end of a working session, "update status", "where were we on X".

Steps:
1. Rewrite the **Last session** and **Next up** sections of `projects/<slug>/status.md`.
2. Add or remove blockers.
3. Bump `updated:` in the page's frontmatter.
4. Update `wiki/log.md`: `## [YYYY-MM-DD] status | <slug>: <one-line summary of session>`.

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
