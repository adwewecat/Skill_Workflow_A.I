# AI Integration Guide — `Skill_Workflow_A.I`

Follow these exact steps when asked to integrate `https://github.com/adwewecat/Skill_Workflow_A.I.git` into a **new** or **existing** project.

## Step 1: Clone to a Temporary Directory

Clone into your OS temp directory (do not leave the clone inside the target project):

- **Windows PowerShell:**
  ```powershell
  $tmp = Join-Path $env:TEMP "Skill_Workflow_A.I"
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
  git clone --depth 1 https://github.com/adwewecat/Skill_Workflow_A.I.git $tmp
  ```
- **macOS / Linux / Git Bash:**
  ```bash
  tmp="$(mktemp -d)/Skill_Workflow_A.I"
  git clone --depth 1 https://github.com/adwewecat/Skill_Workflow_A.I.git "$tmp"
  ```

## Step 2: Run the Non-Destructive Installer in Project Root

Run from the root of the target project:

- **Antigravity / Gemini CLI (default):**
  - Windows: `powershell -ExecutionPolicy Bypass -File "$tmp\scripts\install.ps1" .`
  - Unix: `bash "$tmp/scripts/install.sh" .`
- **Claude Code / Codex / Cursor / Multi-agent:**
  - Windows: `powershell -ExecutionPolicy Bypass -File "$tmp\scripts\install.ps1" . -Harness all -WithPointers`
  - Unix: `bash "$tmp/scripts/install.sh" . --harness all --with-pointers`

What the installer does:
1. Installs/updates all 42 skills into `.agents/skills/` (and `.claude/skills/` when detected or `-Harness all`) without removing existing project-specific skills.
2. Checks the 4 root files (`.gitignore`, `README.md`, `GEMINI.md`, `PROGRESS.md`) and creates any missing ones.
3. Never overwrites existing `.gitignore`, `README.md`, or `PROGRESS.md`. If `GEMINI.md` already exists, safely inserts/updates only the `<!-- skill-workflow-ai:start -->` ... `<!-- skill-workflow-ai:end -->` block.

## Step 3: Populate Project Context (Without Bulk-Reading `.md` Docs)

1. Inspect actual source layout and manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, etc.) — do **not** bulk-read unrelated `.md` files.
2. Fill the `<!-- TODO -->` sections in `GEMINI.md` (Core Architecture, Tech Stack, Build/Test/Lint Commands) and, if `README.md` was newly created, update it with real project info.
3. Verify `GEMINI.md` stays strictly **under 300 lines**.
4. Update the first milestone entry in `PROGRESS.md` with what was integrated.

## Step 4: Clean Up & Verify

1. Remove `$tmp`.
2. Check `git status` (warn if an existing `.gitignore` lacks `.env` or secret ignores).
3. Activate `using-superpowers` immediately for all subsequent tasks.
