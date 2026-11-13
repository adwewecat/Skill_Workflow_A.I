---
name: handoff
description: "Manual trigger ONLY — run ONLY when the user explicitly chats 'nghi ngoi' (or invokes /handoff). Summarizes completed work to the top of PROGRESS.md (rotating >10 entries into ARCHIVE.md) and prepares next-session handoff instructions."
argument-hint: "What will the next session be used for?"
---

Execute an end-of-session handoff so a fresh session can pick up seamlessly:

1. **Update & Rotate `PROGRESS.md` (if in a project workspace):**
   - Prepend a concise summary of what was completed, any bugs fixed, and exact instructions for the next session (`Next:`) at the top of `PROGRESS.md`.
   - Keep **at most 10 entries** under `## Recent Milestones` in `PROGRESS.md`; move entries #11+ to `ARCHIVE.md`.

2. **Write a portable handoff summary:**
   - Save a compact handoff note to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) — do not clutter the project workspace with temp handoff files.
   - Include a "Suggested skills" section naming which skills the next agent should load, and include clear startup instructions for tomorrow's/next session.
   - Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs); reference them by path or URL instead.
   - Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

3. **Git Wrap-up (if requested or at end of verified work):**
   - Remind or verify `git status` / clean tests before any final commit/push (never push failing code or secrets).

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the handoff accordingly.
