---
title: Log
type: log
tags: [log]
created: 2026-05-30
updated: 2026-05-30
---

# Log

Append-only record of ingests, queries, and lint passes. Format:

```
## [YYYY-MM-DD] <op> | <one-line summary>
```

Where `<op>` is one of: `ingest`, `query`, `lint`, `setup`, `note`.
