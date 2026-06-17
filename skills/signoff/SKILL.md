---
name: signoff
description: One-command end-of-session close. Runs three things in a fixed order so the owner never has to type them separately - (1) writes a handoff for the next chat, (2) runs the full wrap-up (architecture self-review, vault lint, index/log/status updates, junk-cleanup asks), (3) prints a copy-paste prompt to continue in a new chat. Use when the owner says "signoff", "sign off", "/signoff", "close out the session", "handoff and wrap up", "end the session and hand off", or otherwise asks for the whole end-of-session ritual in one shot.
license: MIT
metadata:
  version: "1.0"
---

# signoff

End-of-session conductor. The owner runs this instead of typing "write a handoff, then wrap up, then give me a prompt" every time. It composes the steps in a fixed order and does not stop until all three are done.

Composes two existing skills:

- [[handoff]] to capture continuation context as a document.
- [[wrap-up]] for the full closing pipeline.

This skill is the conductor. It does NOT reimplement what those skills do. It invokes them in order and adds the continuation prompt at the end.

## Vault path

Resolve the vault root from `~/.claude/brainkit.json` (the `vaultPath` key). If that file is missing, ask the owner where their Brain vault lives and offer to create the config. Throughout this skill, `<vault>` means that resolved path.

---

## When to run

End of a working session, when the owner is about to close the chat and wants the next chat set up to continue. Triggers: "signoff", "sign off", "/signoff", "close out the session", "handoff and wrap up", "end and hand off", "wrap and hand off and prompt".

## When NOT to run

- Mid-task. This is a closing ritual, not a continuous check.
- When there is nothing to continue (a one-off question, a trivial fix). Just answer or finish; do not ceremony.

---

## Pipeline (fixed order)

### Phase 1 — Handoff

Write a handoff document so the next chat can pick up with full context.

1. Invoke the [[handoff]] skill to compact the session.
2. The output MUST land as a markdown file at `<vault>/handoffs/<YYYY-MM-DD>-<short-slug>.md`, in the established format, not just in chat. Match any existing handoffs already in that folder.
3. The handoff carries: what shipped this session (with commits/PR numbers), state at handoff (branch, deploy status, what is and is not verified), do-next (the concrete next steps), watch-outs (traps, owed ADRs, deploy mechanics), suggested skills.
4. Honesty over comfort: NOT-verified work is labelled NOT-verified. Failures and the fixes for them are stated plainly, never smoothed over.
5. **Prune the superseded predecessor.** If this session picked up from a prior handoff in its own workstream (the one read at boot to get context), once the new handoff is written and carries that predecessor's still-open items forward, delete the predecessor file. Keep one live handoff per workstream, not a growing stack of duplicates.
   - **Only the handoff this chat was working with.** Multiple chats may run in parallel, each continuing a different workstream's handoff. Never delete another workstream's handoff, or any handoff this chat did not pick up from. If you cannot identify with certainty which handoff this session continued, ask the owner before deleting; do not guess.
   - **Carry-forward check before deleting.** Confirm every open item, deferred decision, and watch-out in the predecessor is either resolved this session or restated in the new handoff (or already lives in a durable PRD/spec/status page). If anything would be lost, fold it into the new handoff first, then delete. Never let unfinished work vanish with the file.
   - **De-link or repoint durable references.** Deleting a handoff breaks any reference to it. Handoffs are never wikilinked from index.md, log.md, or wiki pages, so there should be none; if a plain-text mention exists somewhere durable, repoint it to the current handoff or de-link it.
   - A first-of-its-workstream session (no predecessor handoff) deletes nothing.

### Phase 2 — Wrap-up

Invoke the [[wrap-up]] skill and let it run its full pipeline end to end: scope detection, architecture self-review, vault lint, frontmatter status flips, index.md / log.md updates, junk-cleanup asks, and the closing report.

- Do NOT reimplement wrap-up. Invoke it.
- The Phase 1 handoff is now a vault artifact, so the next chat can find it.
- Wrap-up's discipline still applies: ask before deleting anything, never force-push, "Safe to close" only prints when its checks pass.

### Phase 3 — Continuation prompt

After wrap-up prints its closing report, print ONE fenced code block: a copy-paste prompt for the next chat. It must:

- Name the project and the single next objective, derived from the handoff's do-next.
- Point at the handoff file and the driving plan/PRD to read first.
- Carry the non-obvious constraints a fresh agent needs: which branch to build in, deploy mechanics, code-size caps or other gotchas that bit this session, and any owed ADRs.
- Be self-contained: an agent with zero memory of this session can act on it without guessing.

Format it so the owner can copy it straight into a new chat.

---

## Discipline

- **Fixed order.** Handoff first (so wrap-up can reference it and the prompt can derive from it), then wrap-up, then the prompt. Never reorder.
- **Honesty over comfort.** Carried from wrap-up: never claim green, verified, or clean unless it was actually checked this session. If a step was skipped, say which and why.
- **Do not skip wrap-up's asks.** Junk cleanup stays ask-before-delete. Load-bearing assets (branches, plans, ADRs, migrations) are never deleted.
- **One live handoff per workstream.** One handoff document per session, one continuation prompt at the very end. The new handoff replaces the predecessor this chat continued (delete it per Phase 1 step 5). It never touches handoffs belonging to other parallel chats.

---

## Output

Three things, in order:

1. The handoff file path (Phase 1), plus the predecessor handoff deleted (or "none, first of its workstream").
2. Wrap-up's closing report (Phase 2).
3. The fenced continuation prompt (Phase 3).

Then stop. Do not add a fourth thing.
