<#
.SYNOPSIS
🔍 Runs platform_serial static analysis inside Docker.

.DESCRIPTION
Idempotent script. Builds the base image and the analyze image (with
--no-cache if -Force is set), then runs flutter analyze on both the root
package and examples/flutter_serial_monitor.

.PARAMETER Flags
Extra flags for flutter analyze (default: --fatal-infos --fatal-warnings).

.PARAMETER Force
Force rebuild of Docker images with --no-cache.

.PARAMETER DryRun
Print actions without executing them.

.EXAMPLE
scripts\windows\commands\analyze.ps1
scripts\windows\commands\analyze.ps1 -Flags "--fatal-warnings"
scripts\windows\commands\analyze.ps1 -Force
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Intentional colored output.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DryRun',
    Justification = 'DryRun is consumed inside Invoke-Cmd via outer scope.')]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Flags = '--fatal-infos --fatal-warnings',
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Help
)
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir '..\..\..') | Select-Object -ExpandProperty Path
$ComposeFile = Join-Path $RepoRoot 'containers\docker-compose.yml'

function Write-Step($m) { Write-Host "  $m" -ForegroundColor Cyan }
function Write-Ok($m) { Write-Host "✅  $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "⚠️   $m" -ForegroundColor Yellow }
function Invoke-Cmd {
    param([string]$Cmd)
    if ($DryRun) { Write-Warn "dry-run: $Cmd" } else { Invoke-Expression $Cmd }
}

if ($Help) { Get-Help $MyInvocation.MyCommand.Path -Detailed; exit 0 }

Write-Host "🔍 platform_serial — Static Analysis" -ForegroundColor White -BackgroundColor DarkBlue

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "❌  Docker not found. Install Docker Desktop first."
    exit 1
}

$noCache = if ($Force) { '--no-cache' } else { '' }

Write-Step "📦 Building base image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache base"

Write-Step "📦 Building analyze image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache analyze"

Write-Step "🔍 Running analyze container..."
$env:ANALYZE_FLAGS = $Flags
Invoke-Cmd "docker compose -f '$ComposeFile' run --rm analyze"

Write-Ok "Static analysis complete — no issues"

