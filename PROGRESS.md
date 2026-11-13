# Project Progress

> **Rotation Rule:** Prepend new entries to the top of **Recent Milestones**. Keep at most **10 entries** here; move older entries (#11+) to `ARCHIVE.md`.

## Recent Milestones

- **[2026-11-13] Initialized standard Skill_Workflow_A.I bundle**
  - **Done:** Combined 15 `obra/superpowers` skills (auto backbone) and 27 promoted `mattpocock/skills` (scoped to manual/milestone usage) with zero name collisions; added `templates/`, `scripts/install.ps1`, `scripts/install.sh`, `INSTALL.md`, plugin manifests, and verified installers on both fresh and existing project fixtures.
  - **Issues Fixed:** Scoped overlapping `mattpocock/skills` triggers (`tdd`, `code-review`, `diagnosing-bugs`, `wizard`, etc.) so `superpowers` automatic execution is never hijacked; clarified `/handoff` vs `/wizard` roles.
  - **Next:** Integrate into target projects via the 1-shot onboarding prompt.
