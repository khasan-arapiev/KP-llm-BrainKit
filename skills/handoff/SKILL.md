---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
---

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that file is missing, ask the owner where their Brain vault lives and offer to create the config. Below, `<vault>` means that resolved path.

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to `<vault>/handoffs/` (create that folder if it does not exist) with a descriptive, dated filename. These handoffs are transient: the owner reads them and deletes them once the work is picked up, so do not reference them from `index.md`, `log.md`, or any wiki page.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
