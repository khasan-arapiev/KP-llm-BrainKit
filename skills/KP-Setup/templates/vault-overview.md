---
title: {{PROJECT_NAME}} overview
type: project-overview
project: {{SLUG}}
tags: [project, {{SLUG}}]
created: {{TODAY}}
updated: {{TODAY}}
---

# {{PROJECT_NAME}}

{{ONE_LINE_PURPOSE}}

## Status

Phase: planning / building / shipped / paused / archived (pick one).
Health: green / amber / red.
Owner: {{OWNER}}.

## Stack

{{STACK}}

## Location

Code: `{{PROJECT_PATH}}`
Live URL or domain: _(fill in)_
Repo remote: _(fill in if hosted)_

## How to run

_(Local dev command. Build command. Deploy command. Whatever it takes to get this running.)_

## Credentials and integrations

Credentials live outside this vault, in a location you control (a password manager,
an env file outside git, or a secrets folder you never commit).

Read that secret directly when you need keys. Never copy values into the vault, never paste them into chat, never commit them.

### Integrations wired up

_(One bullet per integration. Use labels only, never values. KP-Migrate fills this on import. KP-Setup leaves it empty for you to fill as you wire things up.)_

- _(e.g. **stripe** fields: api_key, webhook_secret — used in `project/webhooks/stripe.js`)_

## Related pages

- [[projects/{{SLUG}}/map]] module map and entry points
- [[projects/{{SLUG}}/context]] domain glossary
- [[projects/{{SLUG}}/review]] Definition of Done
- [[projects/{{SLUG}}/status]] last session and next up
- `projects/{{SLUG}}/plans/` PRDs from KP-Grill sessions
- `projects/{{SLUG}}/decisions/` decisions (ADRs)
- `projects/{{SLUG}}/post-mortems/` post-mortems
- `projects/{{SLUG}}/learnings/` captured learnings

## Why this exists

_(One paragraph: the real problem this project solves. The outcome, not the features.)_

## Notes

_(Free-form. Anything that does not fit a structured page yet.)_
