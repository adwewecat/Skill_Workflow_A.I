<#
.SYNOPSIS
    Integrates Skill_Workflow_A.I (skills + MCP servers + memory/git rules) into a target project safely.
.DESCRIPTION
    Idempotent installer for both new and existing projects.
    - Installs/updates the 42 workflow skills into .agents/skills/ (and .claude/skills/ if detected or requested)
      without removing existing custom skills in the target project.
    - Creates missing root files (.gitignore, README.md, GEMINI.md, PROGRESS.md) without overwriting existing ones.
    - Safely injects/updates the Skill_Workflow_A.I rules block in an existing GEMINI.md using HTML markers.
    - Non-destructively merges playwright, private-journal, and context7 MCP servers into ~/.gemini/config/mcp_config.json (and .mcp.json when Claude harness is active) unless -SkipMcp is set.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = (Get-Location).Path,

    [ValidateSet("auto", "agents", "claude", "all")]
    [string]$Harness = "auto",

    [switch]$WithPointers,

    [switch]$SkipMcp
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
    if ($giContent -notmatch '(?m)^\s*\.private-journal/?\s*$') {
        Write-Warning ".gitignore exists but does not ignore '.private-journal/'. Add it to avoid committing local journal caches."
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

function Merge-McpConfig {
    param(
        [string]$TemplatePath,
        [string]$DestPath
    )
    $destDir = Split-Path -Parent $DestPath
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null

    if (-not (Test-Path $DestPath)) {
        Copy-Item $TemplatePath $DestPath
        Write-Host "[CREATED] MCP config -> $DestPath"
        return
    }

    try {
        $tplObj = (Get-Content $TemplatePath -Raw -Encoding UTF8) | ConvertFrom-Json
        $rawDest = Get-Content $DestPath -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($rawDest)) {
            $destObj = [PSCustomObject]@{}
        } else {
            $destObj = $rawDest | ConvertFrom-Json
        }
    } catch {
        Write-Warning "Could not parse existing JSON in '$DestPath' ($($_.Exception.Message)). Manually merge '$TemplatePath'."
        return
    }

    if (-not ($destObj.PSObject.Properties.Name -contains "mcpServers") -or $null -eq $destObj.mcpServers) {
        $destObj | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    $existingServers = $destObj.mcpServers.PSObject.Properties.Name
    $added = @()
    foreach ($prop in $tplObj.mcpServers.PSObject.Properties) {
        if ($prop.Name -notin $existingServers) {
            $destObj.mcpServers | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
            $added += $prop.Name
        }
    }

    if ($added.Count -gt 0) {
        $json = ($destObj | ConvertTo-Json -Depth 10) + "`n"
        [System.IO.File]::WriteAllText($DestPath, $json, [System.Text.UTF8Encoding]::new($false))
        Write-Host "[MERGED] Added MCP servers ($($added -join ', ')) -> $DestPath"
    } else {
        Write-Host "[SKIP] MCP config already contains all workflow servers -> $DestPath"
    }
}

# 5. Global Antigravity MCP config (+ project .mcp.json when Claude harness is active)
if (-not $SkipMcp) {
    $mcpTemplatePath = Join-Path $TemplatesDir "mcp_config.json.template"
    $userHome = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { [Environment]::GetFolderPath("UserProfile") }
    $globalMcpPath = Join-Path $userHome ".gemini\config\mcp_config.json"
    Merge-McpConfig -TemplatePath $mcpTemplatePath -DestPath $globalMcpPath

    if ($installClaude) {
        Merge-McpConfig -TemplatePath $mcpTemplatePath -DestPath (Join-Path $TargetRoot ".mcp.json")
    }
} else {
    Write-Host "[SKIP] MCP config installation skipped (-SkipMcp)"
}

Write-Host ""
Write-Host "Integration complete in: $TargetRoot"
Write-Host "Next step for AI: Inspect project manifest/structure (without bulk-reading .md files) and fill TODO slots in GEMINI.md / README.md."

