#!/usr/bin/env bash
set -euo pipefail

# Idempotent installer for Skill_Workflow_A.I into a new or existing project.
# Usage:
#   bash scripts/install.sh [TARGET_DIR] [--harness auto|agents|claude|all] [--with-pointers] [--skip-mcp]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_SRC="${REPO_ROOT}/skills"
TEMPLATES_DIR="${REPO_ROOT}/templates"

TARGET_DIR="."
HARNESS="auto"
WITH_POINTERS=false
SKIP_MCP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --harness)
      HARNESS="${2:-auto}"
      shift 2
      ;;
    --with-pointers)
      WITH_POINTERS=true
      shift
      ;;
    --skip-mcp)
      SKIP_MCP=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [TARGET_DIR] [--harness auto|agents|claude|all] [--with-pointers] [--skip-mcp]"
      exit 0
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

TARGET_ROOT="$(cd "$TARGET_DIR" && pwd)"

install_skill_set() {
  local dest_root="$1"
  mkdir -p "$dest_root"
  local count=0
  for skill_dir in "${SKILLS_SRC}"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_dir="${skill_dir%/}"
    local name
    name="$(basename "$skill_dir")"
    rm -rf "${dest_root:?}/${name}"
    cp -R "$skill_dir" "${dest_root}/${name}"
    count=$((count + 1))
  done
  echo "[OK] Installed/updated ${count} skills -> ${dest_root}"
}

install_agents=false
install_claude=false
case "$HARNESS" in
  auto)
    install_agents=true
    if [ -d "${TARGET_ROOT}/.claude" ]; then
      install_claude=true
    fi
    ;;
  agents)
    install_agents=true
    ;;
  claude)
    install_claude=true
    ;;
  all)
    install_agents=true
    install_claude=true
    ;;
  *)
    echo "Unknown --harness value: ${HARNESS}" >&2
    exit 1
    ;;
esac

if [ "$install_agents" = true ]; then
  install_skill_set "${TARGET_ROOT}/.agents/skills"
fi
if [ "$install_claude" = true ]; then
  install_skill_set "${TARGET_ROOT}/.claude/skills"
fi

# 1. .gitignore
if [ ! -f "${TARGET_ROOT}/.gitignore" ]; then
  cp "${TEMPLATES_DIR}/.gitignore.template" "${TARGET_ROOT}/.gitignore"
  echo "[CREATED] .gitignore"
else
  echo "[SKIP] .gitignore already exists"
  if ! grep -qE '^\s*\.env\b' "${TARGET_ROOT}/.gitignore"; then
    echo "[WARN] .gitignore exists but does not explicitly ignore '.env'. Review it before committing." >&2
  fi
  if ! grep -qE '^\s*\.private-journal/?\s*$' "${TARGET_ROOT}/.gitignore"; then
    echo "[WARN] .gitignore exists but does not ignore '.private-journal/'. Add it to avoid committing local journal caches." >&2
  fi
fi

# 2. README.md
if [ ! -f "${TARGET_ROOT}/README.md" ]; then
  cp "${TEMPLATES_DIR}/README.md.template" "${TARGET_ROOT}/README.md"
  echo "[CREATED] README.md"
else
  echo "[SKIP] README.md already exists"
fi

# 3. GEMINI.md
GEMINI_PATH="${TARGET_ROOT}/GEMINI.md"
GEMINI_TEMPLATE="${TEMPLATES_DIR}/GEMINI.md.template"
START_MARKER="<!-- skill-workflow-ai:start -->"
END_MARKER="<!-- skill-workflow-ai:end -->"

if [ ! -f "$GEMINI_PATH" ]; then
  cp "$GEMINI_TEMPLATE" "$GEMINI_PATH"
  echo "[CREATED] GEMINI.md"
else
  TMP_BLOCK="$(mktemp)"
  sed -n "/${START_MARKER}/,/${END_MARKER}/p" "$GEMINI_TEMPLATE" > "$TMP_BLOCK"

  if grep -qF "$START_MARKER" "$GEMINI_PATH" && grep -qF "$END_MARKER" "$GEMINI_PATH"; then
    TMP_OUT="$(mktemp)"
    awk -v block_file="$TMP_BLOCK" -v start="$START_MARKER" -v end="$END_MARKER" '
      $0 ~ start {
        while ((getline line < block_file) > 0) print line
        close(block_file)
        skip = 1
        next
      }
      $0 ~ end { skip = 0; next }
      !skip { print }
    ' "$GEMINI_PATH" > "$TMP_OUT"
    mv "$TMP_OUT" "$GEMINI_PATH"
    echo "[UPDATED] GEMINI.md (refreshed managed Skill_Workflow_A.I block)"
  else
    printf "\n" >> "$GEMINI_PATH"
    cat "$TMP_BLOCK" >> "$GEMINI_PATH"
    echo "[MERGED] GEMINI.md (appended Skill_Workflow_A.I rules block)"
  fi
  rm -f "$TMP_BLOCK"
fi

GEMINI_LINES="$(wc -l < "$GEMINI_PATH" | tr -d ' ')"
if [ "$GEMINI_LINES" -gt 300 ]; then
  echo "[WARN] GEMINI.md is ${GEMINI_LINES} lines (exceeds 300-line cap). Trim project notes." >&2
else
  echo "[CHECK] GEMINI.md line count: ${GEMINI_LINES} / 300"
fi

# 4. PROGRESS.md
if [ ! -f "${TARGET_ROOT}/PROGRESS.md" ]; then
  TODAY="$(date +%Y-%m-%d)"
  sed "s/YYYY-MM-DD/${TODAY}/g" "${TEMPLATES_DIR}/PROGRESS.md.template" > "${TARGET_ROOT}/PROGRESS.md"
  echo "[CREATED] PROGRESS.md"
else
  echo "[SKIP] PROGRESS.md already exists"
fi

# Optional cross-harness pointers
if [ "$WITH_POINTERS" = true ]; then
  if [ ! -f "${TARGET_ROOT}/AGENTS.md" ]; then
    cp "${TEMPLATES_DIR}/AGENTS.md.template" "${TARGET_ROOT}/AGENTS.md"
    echo "[CREATED] AGENTS.md pointer"
  fi
  if [ ! -f "${TARGET_ROOT}/CLAUDE.md" ]; then
    cp "${TEMPLATES_DIR}/CLAUDE.md.template" "${TARGET_ROOT}/CLAUDE.md"
    echo "[CREATED] CLAUDE.md pointer"
  fi
fi

merge_mcp_config() {
  local tpl_path="$1"
  local dest_path="$2"
  mkdir -p "$(dirname "$dest_path")"

  if [ ! -f "$dest_path" ]; then
    cp "$tpl_path" "$dest_path"
    echo "[CREATED] MCP config -> ${dest_path}"
    return
  fi

  local tpl_native="$tpl_path"
  local dest_native="$dest_path"
  if command -v cygpath >/dev/null 2>&1; then
    tpl_native="$(cygpath -m "$tpl_path")"
    dest_native="$(cygpath -m "$dest_path")"
  fi

  if command -v node >/dev/null 2>&1; then
    node -e '
      const fs = require("fs");
      const [tplFile, destFile] = process.argv.slice(1);
      const tpl = JSON.parse(fs.readFileSync(tplFile, "utf8"));
      const raw = fs.readFileSync(destFile, "utf8").replace(/^\uFEFF/, "");
      const dest = raw.trim() ? JSON.parse(raw) : {};
      if (!dest.mcpServers || typeof dest.mcpServers !== "object" || Array.isArray(dest.mcpServers)) {
        dest.mcpServers = {};
      }
      const added = [];
      for (const [k, v] of Object.entries(tpl.mcpServers || {})) {
        if (!Object.prototype.hasOwnProperty.call(dest.mcpServers, k)) {
          dest.mcpServers[k] = v;
          added.push(k);
        }
      }
      if (added.length > 0) {
        fs.writeFileSync(destFile, JSON.stringify(dest, null, 2) + "\n", "utf8");
        console.log("[MERGED] Added MCP servers (" + added.join(", ") + ") -> " + destFile);
      } else {
        console.log("[SKIP] MCP config already contains all workflow servers -> " + destFile);
      }
    ' "$tpl_native" "$dest_native" || echo "[WARN] Could not merge '${dest_path}'. Manually merge '${tpl_path}'." >&2
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
tpl_file, dest_file = sys.argv[1], sys.argv[2]
with open(tpl_file, "r", encoding="utf-8-sig") as f:
    tpl = json.load(f)
with open(dest_file, "r", encoding="utf-8-sig") as f:
    raw = f.read().strip()
dest = json.loads(raw) if raw else {}
if not isinstance(dest.get("mcpServers"), dict):
    dest["mcpServers"] = {}
added = []
for k, v in (tpl.get("mcpServers") or {}).items():
    if k not in dest["mcpServers"]:
        dest["mcpServers"][k] = v
        added.append(k)
if added:
    with open(dest_file, "w", encoding="utf-8") as f:
        json.dump(dest, f, indent=2)
        f.write("\n")
    print("[MERGED] Added MCP servers (" + ", ".join(added) + ") -> " + dest_file)
else:
    print("[SKIP] MCP config already contains all workflow servers -> " + dest_file)
' "$tpl_native" "$dest_native" || echo "[WARN] Could not merge '${dest_path}'. Manually merge '${tpl_path}'." >&2
  else
    echo "[WARN] Neither node nor python3 found to auto-merge JSON. Manually merge '${tpl_path}' into '${dest_path}'." >&2
  fi
}

# 5. Global Antigravity MCP config (+ project .mcp.json when Claude harness is active)
if [ "$SKIP_MCP" = false ]; then
  MCP_TEMPLATE="${TEMPLATES_DIR}/mcp_config.json.template"
  merge_mcp_config "$MCP_TEMPLATE" "${HOME}/.gemini/config/mcp_config.json"
  if [ "$install_claude" = true ]; then
    merge_mcp_config "$MCP_TEMPLATE" "${TARGET_ROOT}/.mcp.json"
  fi
else
  echo "[SKIP] MCP config installation skipped (--skip-mcp)"
fi

echo ""
echo "Integration complete in: ${TARGET_ROOT}"
echo "Next step for AI: Inspect project manifest/structure (without bulk-reading .md files) and fill TODO slots in GEMINI.md / README.md."
