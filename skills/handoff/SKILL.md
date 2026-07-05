---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
license: MIT
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to `<vault>\handoffs\` (`<vault>` is the vault root from `~/.claude/brainkit.json`, key `vaultPath`) (create that folder if it does not exist) with a descriptive, dated filename (`<YYYY-MM-DD>-<short-slug>.md`). These handoffs are transient: they get deleted once picked up — by the owner, or by the signoff skill's predecessor-pruning rule (signoff owns the agent-side deletion procedure). So never reference them from `index.md`, `log.md`, or any wiki page with a `[[wikilink]]`; plain-text path mentions only.

Every handoff carries these sections (this is the canonical section contract; signoff references it):

1. **What shipped this session** — with commit hashes / PR numbers.
2. **State at handoff** — branch, worktree, deploy status, and explicitly what is and is NOT verified.
3. **Do next** — the concrete next steps, most important first.
4. **Watch-outs** — traps, shared-tree/branch hazards, owed ADRs, deploy mechanics that bit this session.
5. **Suggested skills** — skills the next agent should invoke.

Honesty over comfort: NOT-verified work is labelled NOT-verified; failures and their fixes are stated plainly, never smoothed over.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
