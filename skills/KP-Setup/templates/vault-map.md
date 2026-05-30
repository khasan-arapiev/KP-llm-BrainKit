---
title: {{PROJECT_NAME}} map
type: project-map
project: {{SLUG}}
tags: [project, {{SLUG}}, map]
created: {{TODAY}}
updated: {{TODAY}}
---

# {{PROJECT_NAME}} map

One-page navigational map for this codebase. Entry points, modules, layering, naming. Updated when the structure changes.

## Entry points

| What | Path |
|---|---|
| _(e.g. dev server)_ | _(e.g. `project/index.html`)_ |
| _(e.g. main API)_ | _(e.g. `project/server.js`)_ |
| _(e.g. background worker)_ | _(e.g. `project/worker.py`)_ |

## Modules

| Module | Folder | Owns | Talks to |
|---|---|---|---|
| _(e.g. auth)_ | _(e.g. `project/lib/auth/`)_ | _(login, sessions)_ | _(db, mailer)_ |

## Layering

_(One paragraph or list: which layer depends on which. The rule a future edit must not break.)_

## Conventions

- Naming: _(e.g. kebab-case files, PascalCase components)_
- Tests: _(if any)_
- Deploy: _(short summary, full details in code or in a deploy doc)_

## See also

- [[projects/{{SLUG}}/overview]]
- [[projects/{{SLUG}}/context]]
