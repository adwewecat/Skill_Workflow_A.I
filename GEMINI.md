# Skill_Workflow_A.I — Repo Rules

> Strictly under 300 lines. On session start, read ONLY `GEMINI.md` and `PROGRESS.md`.

## Core Architecture

- **Purpose:** Unified AI coding workflow combining `obra/superpowers` (automatic backbone) and `mattpocock/skills` (manual milestone tools) plus memory-rotation and Git standards.
- **Key Paths:**
  - `skills/` — Flat 42-skill library (15 `obra/superpowers` + 27 promoted `mattpocock/skills`, zero name collisions).
  - `templates/` — Starter templates (`.gitignore`, `README.md`, `GEMINI.md`, `PROGRESS.md`, `ARCHIVE.md`, `AGENTS.md`, `CLAUDE.md`).
  - `scripts/` — Idempotent per-project installers (`install.ps1`, `install.sh`).
  - `hooks/`, `assets/`, `.antigravity-plugin/`, `.claude-plugin/`, `gemini-extension.json` — Plugin manifests & SessionStart hook.

## Tech Stack & Verification Commands

- **Formats / Runtimes:** Markdown (`SKILL.md`), PowerShell (`install.ps1`), POSIX Bash (`install.sh`, `hooks/`), JSON manifests.
- **Validation:** Test `scripts/install.ps1` and `scripts/install.sh` against temporary empty + existing project fixtures before committing.

<!-- skill-workflow-ai:start -->
## Workflow & Memory Rules (Skill_Workflow_A.I)

### 1. Memory & Auto-Init (Context Budget Protection)
- **Layered Session Startup:** At the start of every session, read **ONLY `GEMINI.md` and `PROGRESS.md`**. Do NOT bulk-read `ARCHIVE.md` or other `.md` files unless a path is explicitly named in the current task or loaded as an active skill (`SKILL.md`).
- **Auto-Initialization:** Before writing or modifying code, verify all 4 root files exist: `.gitignore`, `README.md`, `GEMINI.md` (< 300 lines), `PROGRESS.md`. Create any missing file immediately; leave existing ones intact.
- **History Rotation (`PROGRESS.md`):** After each verified change or bugfix, prepend a brief entry at the top of `PROGRESS.md`. Keep **at most 10 recent entries**; move older entries (#11+) into `ARCHIVE.md`.

### 2. Execution Workflow
- **Main Backbone (`obra/superpowers` — Auto-On):** Follow for every task: load `using-superpowers` -> `brainstorming` / `writing-plans` -> split work into independent tasks -> dispatch fresh-context subagents per task (`subagent-driven-development` / `dispatching-parallel-agents`) -> strict RED-GREEN-REFACTOR `test-driven-development` -> run `verification-before-completion` with real command output before claiming success.
- **Manual / Milestone Tools (`mattpocock/skills` — Manual Only):** Never auto-trigger on routine tasks. Run only when explicitly invoked or at major milestones:
  - `/grill-with-docs`: Lock new rules, domain terms (`GLOSSARY.md`), and architecture decisions (`docs/adr/`).
  - `/handoff`: Package end-of-session handoff summary + rotate `PROGRESS.md`. *(Note: upstream `/wizard` creates interactive bash setup scripts for `.env`/secrets/infra; if `/wizard` is invoked specifically for end-of-session handoff documentation, run `/handoff` + `PROGRESS.md` wrap-up instead.)*

### 3. Clean Code & Git / GitHub Standards
- **Clean Code:** Immediately delete unused variables, functions, imports, and dead files. Comment only **WHY** (non-obvious invariants, edge cases, special error handling); never comment obvious code.
- **Git & GitHub:**
  - Never push failing, untested, or unverified code.
  - `git commit` locally only after finishing and verifying each task.
  - `git push` to GitHub right after completing a full feature, a complete bugfix, or before ending a session — always inspect `git status` and staged diff first to ensure no `.env`, secrets, keys, or credentials are included.
<!-- skill-workflow-ai:end -->
