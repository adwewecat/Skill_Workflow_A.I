# Project Progress

> **Rotation Rule:** Prepend new entries to the top of **Recent Milestones**. Keep at most **10 entries** here; move older entries (#11+) to `ARCHIVE.md`.

## Recent Milestones

- **[2026-11-13] Integrated Playwright, Private Journal, and Context7 MCP servers**
  - **Done:** Configured `playwright` (`@playwright/mcp@latest`), `private-journal` (`github:obra/private-journal-mcp`), and `context7` (`@upstash/context7-mcp@latest`) in Antigravity global `mcp_config.json` and added portable repo `mcp_config.json` + `templates/mcp_config.json.template`; updated `GEMINI.md` and `templates/GEMINI.md.template` with explicit Context7 lookup, Playwright UI verification, and Private Journal rules; ignored `.private-journal/` in `.gitignore` and `templates/.gitignore.template`; added non-destructive MCP merging (`-SkipMcp` / `--skip-mcp`) to `scripts/install.ps1` and `scripts/install.sh`; updated `README.md` (including 1-shot prompt) and `INSTALL.md`.
  - **Verification:** Verified JSON-RPC `initialize` responses from all 3 MCP servers, validated all JSON manifests/configs, confirmed `< 300` line caps (`GEMINI.md` 44 lines, template 49 lines), and tested `install.ps1` and `install.sh` across fresh, existing-merge, `.claude`, idempotency, and `--skip-mcp` fixtures.
  - **Next:** Ready to integrate into new or existing projects via the updated 1-shot prompt.

- **[2026-11-13] Updated manual triggers & GitHub documentation**
  - **Done:** Replaced slash-only workflow commands with plain chat triggers (`"quy trinh moi"` -> `grill-with-docs`, `"nghi ngoi"` -> `handoff` + `PROGRESS.md`/`ARCHIVE.md` rotation, `"cau hinh"` -> `wizard`); updated `README.md` with full mechanism/reason documentation and refreshed `INSTALL.md`, `GEMINI.md`, `templates/GEMINI.md.template`, and `.antigravity-plugin/plugin.json`.
  - **Issues Fixed:** Removed `disable-model-invocation: true` / `allow_implicit_invocation: false` on `grill-with-docs`, `handoff`, and `wizard` (with strict manual-only descriptions) so plain-text Vietnamese triggers work reliably across harnesses.
  - **Next:** Ready to integrate into new or existing projects via the 1-shot prompt.

- **[2026-11-13] Initialized standard Skill_Workflow_A.I bundle**
  - **Done:** Combined 15 `obra/superpowers` skills (auto backbone) and 27 promoted `mattpocock/skills` (scoped to manual/milestone usage) with zero name collisions; added `templates/`, `scripts/install.ps1`, `scripts/install.sh`, `INSTALL.md`, plugin manifests, and verified installers on both fresh and existing project fixtures.
  - **Issues Fixed:** Scoped overlapping `mattpocock/skills` triggers (`tdd`, `code-review`, `diagnosing-bugs`, `wizard`, etc.) so `superpowers` automatic execution is never hijacked; clarified `/handoff` vs `/wizard` roles.
  - **Next:** Integrate into target projects via the 1-shot onboarding prompt.

