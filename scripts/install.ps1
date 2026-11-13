<#
.SYNOPSIS
    Integrates Skill_Workflow_A.I (skills + memory/git rules) into a target project safely.
.DESCRIPTION
    Idempotent installer for both new and existing projects.
    - Installs/updates the 42 workflow skills into .agents/skills/ (and .claude/skills/ if detected or requested)
      without removing existing custom skills in the target project.
    - Creates missing root files (.gitignore, README.md, GEMINI.md, PROGRESS.md) without overwriting existing ones.
    - Safely injects/updates the Skill_Workflow_A.I rules block in an existing GEMINI.md using HTML markers.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = (Get-Location).Path,

    [ValidateSet("auto", "agents", "claude", "all")]
    [string]$Harness = "auto",

    [switch]$WithPointers
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TargetRoot = (Resolve-Path $TargetDir).Path
$SkillsSrc = Join-Path $RepoRoot "skills"
$TemplatesDir = Join-Path $RepoRoot "templates"

function Install-SkillSet {
    param([string]$DestSkillsRoot)
    New-Item -ItemType Directory -Force -Path $DestSkillsRoot | Out-Null
    $count = 0
    foreach ($skillDir in Get-ChildItem -Directory -Path $SkillsSrc) {
        $destSkill = Join-Path $DestSkillsRoot $skillDir.Name
        if (Test-Path $destSkill) {
            Remove-Item -Recurse -Force $destSkill
        }
        Copy-Item -Recurse -Force $skillDir.FullName $destSkill
        $count++
    }
    Write-Host "[OK] Installed/updated $count skills -> $DestSkillsRoot"
}

$installAgents = ($Harness -in @("auto", "agents", "all"))
$installClaude = ($Harness -in @("claude", "all")) -or ($Harness -eq "auto" -and (Test-Path (Join-Path $TargetRoot ".claude")))

if ($installAgents) {
    Install-SkillSet (Join-Path $TargetRoot ".agents\skills")
}
if ($installClaude) {
    Install-SkillSet (Join-Path $TargetRoot ".claude\skills")
}

# 1. .gitignore
$gitignorePath = Join-Path $TargetRoot ".gitignore"
if (-not (Test-Path $gitignorePath)) {
    Copy-Item (Join-Path $TemplatesDir ".gitignore.template") $gitignorePath
    Write-Host "[CREATED] .gitignore"
} else {
    Write-Host "[SKIP] .gitignore already exists"
    $giContent = Get-Content $gitignorePath -Raw -ErrorAction SilentlyContinue
    if ($giContent -notmatch '(?m)^\s*\.env\b') {
        Write-Warning ".gitignore exists but does not explicitly ignore '.env'. Review it before committing."
    }
}

# 2. README.md
$readmePath = Join-Path $TargetRoot "README.md"
if (-not (Test-Path $readmePath)) {
    Copy-Item (Join-Path $TemplatesDir "README.md.template") $readmePath
    Write-Host "[CREATED] README.md"
} else {
    Write-Host "[SKIP] README.md already exists"
}

# 3. GEMINI.md (create if missing, or merge managed rules block non-destructively)
$geminiPath = Join-Path $TargetRoot "GEMINI.md"
$geminiTemplate = Get-Content (Join-Path $TemplatesDir "GEMINI.md.template") -Raw
$startMarker = "<!-- skill-workflow-ai:start -->"
$endMarker = "<!-- skill-workflow-ai:end -->"

if (-not (Test-Path $geminiPath)) {
    Set-Content -Path $geminiPath -Value $geminiTemplate -NoNewline -Encoding UTF8
    Write-Host "[CREATED] GEMINI.md"
} else {
    $existingGemini = Get-Content $geminiPath -Raw
    if ($geminiTemplate -match "(?s)($([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker)))") {
        $managedBlock = $Matches[1]
        $pattern = "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
        if ($existingGemini -match $pattern) {
            $updated = [regex]::Replace($existingGemini, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $managedBlock })
            Set-Content -Path $geminiPath -Value $updated -NoNewline -Encoding UTF8
            Write-Host "[UPDATED] GEMINI.md (refreshed managed Skill_Workflow_A.I block)"
        } else {
            $sep = if ($existingGemini.EndsWith("`n")) { "`n" } else { "`n`n" }
            Set-Content -Path $geminiPath -Value ($existingGemini + $sep + $managedBlock + "`n") -NoNewline -Encoding UTF8
            Write-Host "[MERGED] GEMINI.md (appended Skill_Workflow_A.I rules block)"
        }
    }
}

$geminiLines = (Get-Content $geminiPath).Count
if ($geminiLines -gt 300) {
    Write-Warning "GEMINI.md is $geminiLines lines (exceeds 300-line cap). Trim project notes or move details out."
} else {
    Write-Host "[CHECK] GEMINI.md line count: $geminiLines / 300"
}

# 4. PROGRESS.md
$progressPath = Join-Path $TargetRoot "PROGRESS.md"
if (-not (Test-Path $progressPath)) {
    $today = Get-Date -Format "yyyy-MM-dd"
    $progressContent = (Get-Content (Join-Path $TemplatesDir "PROGRESS.md.template") -Raw).Replace("YYYY-MM-DD", $today)
    Set-Content -Path $progressPath -Value $progressContent -NoNewline -Encoding UTF8
    Write-Host "[CREATED] PROGRESS.md"
} else {
    Write-Host "[SKIP] PROGRESS.md already exists"
}

# Optional cross-harness pointers (only if missing and requested or .claude exists)
if ($WithPointers) {
    $agentsMd = Join-Path $TargetRoot "AGENTS.md"
    if (-not (Test-Path $agentsMd)) {
        Copy-Item (Join-Path $TemplatesDir "AGENTS.md.template") $agentsMd
        Write-Host "[CREATED] AGENTS.md pointer"
    }
    $claudeMd = Join-Path $TargetRoot "CLAUDE.md"
    if (-not (Test-Path $claudeMd)) {
        Copy-Item (Join-Path $TemplatesDir "CLAUDE.md.template") $claudeMd
        Write-Host "[CREATED] CLAUDE.md pointer"
    }
}

Write-Host ""
Write-Host "Integration complete in: $TargetRoot"
Write-Host "Next step for AI: Inspect project manifest/structure (without bulk-reading .md files) and fill TODO slots in GEMINI.md / README.md."

