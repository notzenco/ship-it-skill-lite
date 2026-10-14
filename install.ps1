# Install Ship-It for Claude Code, Codex, or Cursor.
param(
  [Parameter(Position = 0)]
  [string]$Tool,
  [string]$Project
)

$ErrorActionPreference = "Stop"

function Show-Usage {
  Write-Host "Usage: ./install.ps1 <claude|codex|cursor> [-Project DIR]"
  Write-Host ""
  Write-Host "Examples:"
  Write-Host "  ./install.ps1 claude"
  Write-Host "  ./install.ps1 codex -Project ."
  Write-Host "  ./install.ps1 cursor -Project ."
}

if (-not $Tool -or $Tool -eq "-h" -or $Tool -eq "--help") {
  Show-Usage
  exit 0
}

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Skill = Join-Path $Root "skill"

function Copy-Skill([string]$Dest) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Dest "references") | Out-Null
  Copy-Item (Join-Path $Skill "SKILL.md") (Join-Path $Dest "SKILL.md") -Force
  Copy-Item (Join-Path $Skill "AGENTS.md") (Join-Path $Dest "AGENTS.md") -Force
  $refDest = Join-Path $Dest "references"
  if (Test-Path $refDest) { Remove-Item $refDest -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $refDest | Out-Null
  Copy-Item (Join-Path $Skill "references\*") $refDest -Recurse -Force
  $catalog = Join-Path $Skill "catalog"
  if (Test-Path $catalog) {
    foreach ($name in @("catalog", "scripts")) {
      $target = Join-Path $Dest $name
      if (Test-Path $target) { Remove-Item $target -Recurse -Force }
      New-Item -ItemType Directory -Force -Path $target | Out-Null
      Copy-Item (Join-Path $Skill "$name\*") $target -Recurse -Force
    }
  }
}

function Add-AgentsBlock([string]$File) {
  $block = @"
<!-- ship-it-skill:start -->
## Ship-It pre-launch audit

When the user asks to launch, ship, or run a pre-launch audit on a Next.js, Supabase, Stripe, or Vercel app, follow the Ship-It skill (SKILL.md). Read its references/checks.md. Write the scorecard before changing code.
<!-- ship-it-skill:end -->
"@
  if (Test-Path $File) {
    $text = Get-Content -Raw -Path $File
    $pattern = "(?s)<!-- ship-it-skill:start -->.*?<!-- ship-it-skill:end -->"
    if ($text -match "ship-it-skill:start") {
      $text = [regex]::Replace($text, $pattern, "").TrimEnd()
      Set-Content -Path $File -Value ($text + "`r`n`r`n" + $block + "`r`n") -Encoding utf8
    } else {
      Add-Content -Path $File -Value ("`r`n" + $block) -Encoding utf8
    }
  } else {
    Set-Content -Path $File -Value $block -Encoding utf8
  }
}

switch ($Tool) {
  "claude" {
    if ($Project) {
      $dest = Join-Path (Resolve-Path $Project) ".claude\skills\ship-it"
    } else {
      $dest = Join-Path $env:USERPROFILE ".claude\skills\ship-it"
    }
    Copy-Skill $dest
    Write-Host "installed: $dest"
    Write-Host "tool: claude"
  }
  "codex" {
    if ($Project) {
      $base = (Resolve-Path $Project).Path
      Copy-Skill (Join-Path $base ".codex\skills\ship-it")
      Copy-Skill (Join-Path $base ".agents\skills\ship-it")
      Add-AgentsBlock (Join-Path $base "AGENTS.md")
      Write-Host "installed: $base\.codex\skills\ship-it"
      Write-Host "installed: $base\.agents\skills\ship-it"
      Write-Host "updated: $base\AGENTS.md"
    } else {
      Copy-Skill (Join-Path $env:USERPROFILE ".codex\skills\ship-it")
      Copy-Skill (Join-Path $env:USERPROFILE ".agents\skills\ship-it")
      Write-Host "installed: $($env:USERPROFILE)\.codex\skills\ship-it"
      Write-Host "installed: $($env:USERPROFILE)\.agents\skills\ship-it"
    }
    Write-Host "tool: codex"
  }
  "cursor" {
    if (-not $Project) { $Project = (Get-Location).Path }
    $base = (Resolve-Path $Project).Path
    New-Item -ItemType Directory -Force -Path (Join-Path $base ".cursor\rules") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $base ".cursor\commands") | Out-Null
    Copy-Item (Join-Path $Skill "cursor\rules\ship-it.mdc") (Join-Path $base ".cursor\rules\ship-it.mdc") -Force
    Copy-Item (Join-Path $Skill "cursor\commands\ship-it.md") (Join-Path $base ".cursor\commands\ship-it.md") -Force
    $payload = Join-Path $base ".cursor\ship-it"
    if (Test-Path $payload) { Remove-Item $payload -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $payload | Out-Null
    Copy-Item (Join-Path $Skill "references\*") $payload -Recurse -Force
    if (Test-Path (Join-Path $Skill "scripts")) {
      foreach ($name in @("scripts", "catalog")) {
        $target = Join-Path $payload $name
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        Copy-Item (Join-Path $Skill "$name\*") $target -Recurse -Force
      }
    }
    Write-Host "installed: $base\.cursor\rules\ship-it.mdc"
    Write-Host "installed: $base\.cursor\commands\ship-it.md"
    Write-Host "tool: cursor"
  }
  default {
    Write-Host "Error: tool must be claude, codex, or cursor"
    Show-Usage
    exit 1
  }
}
