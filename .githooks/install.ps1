<#
.SYNOPSIS
🪝 Installs platform_serial git hooks (Windows).

.DESCRIPTION
Idempotent installer. Sets git core.hooksPath to .githooks/ for
this repository. Safe to run multiple times.

.PARAMETER DryRun
Print actions without changing anything.

.PARAMETER Uninstall
Remove the hooksPath configuration.

.EXAMPLE
.githooks\install.ps1
.githooks\install.ps1 -DryRun
.githooks\install.ps1 -Uninstall
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Interactive installer uses colored host output.')]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$Uninstall,
    [switch]$Help
)
$ErrorActionPreference = 'Stop'

function Write-Step($m) { Write-Host "  $m"    -ForegroundColor Cyan }
function Write-Ok($m) { Write-Host "✅  $m"  -ForegroundColor Green }
function Write-Warn($m) { Write-Host "⚠️   $m" -ForegroundColor Yellow }
function Write-Fail($m) { Write-Host "❌  $m"  -ForegroundColor Red; exit 1 }
function Invoke-Cmd {
    param([string]$Cmd)
    if ($DryRun) { Write-Warn "dry-run: $Cmd" } else { Invoke-Expression $Cmd }
}

if ($Help) { Get-Help $MyInvocation.MyCommand.Path -Detailed; exit 0 }

# Locate repo root
$RepoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $RepoRoot) { Write-Fail "Not inside a git repository." }
$HooksDir = Join-Path $RepoRoot '.githooks'
if (-not (Test-Path $HooksDir)) {
    Write-Fail ".githooks/ not found in $RepoRoot"
}

Write-Host ""
Write-Host "🪝 platform_serial git hooks installer" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""

# ── Uninstall ────────────────────────────────────────────────
if ($Uninstall) {
    $current = (git -C $RepoRoot config --local core.hooksPath 2>$null)
    if (-not $current) {
        Write-Warn "core.hooksPath is not set — nothing to uninstall."
    }
    else {
        Invoke-Cmd "git -C '$RepoRoot' config --local --unset core.hooksPath"
        Write-Ok "core.hooksPath removed (was: $current)"
    }
    exit 0
}

# ── Set hooksPath ────────────────────────────────────────────
$current = (git -C $RepoRoot config --local core.hooksPath 2>$null)
if ($current -eq '.githooks') {
    Write-Ok "core.hooksPath already set to .githooks — nothing to do."
}
else {
    Write-Step "Setting git config core.hooksPath = .githooks ..."
    Invoke-Cmd "git -C '$RepoRoot' config --local core.hooksPath .githooks"
    Write-Ok "core.hooksPath = .githooks"
}

# ── Verify git version ───────────────────────────────────────
$gitVersion = (git --version) -replace 'git version ', ''
$gitMajorMinor = $gitVersion.Split('.')[0..1] -join '.'
Write-Step "Git version: $gitVersion"
if ([version]$gitMajorMinor -lt [version]'2.9') {
    Write-Warn "Git $gitVersion is old. core.hooksPath requires Git 2.9+."
}

Write-Host ""
Write-Ok "Git hooks installed! 🎉"
Write-Host ""
Write-Host "  Hooks active:" -ForegroundColor Cyan
Write-Host "    post-checkout — quality gate on new branch creation"
Write-Host "    pre-commit    — analyze + test alignment + CHANGELOG check"
Write-Host "    pre-push      — full test suite + coverage gate + push guard"
Write-Host "    commit-msg    — Conventional Commits format validation"
Write-Host ""
Write-Host "  Bypass (emergency): `$env:GIT_HOOKS_BYPASS=1; git <command>"
Write-Host "  Uninstall:          .githooks\install.ps1 -Uninstall"
Write-Host ""

