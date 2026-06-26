<#
.SYNOPSIS
🧪 Runs platform_serial tests with coverage inside Docker.

.DESCRIPTION
Idempotent script. Builds the base image and the test image (with
--no-cache if -Force is set), then runs the test container.
Coverage report is written to ./coverage/lcov.info.

.PARAMETER MinCoverage
Minimum acceptable line coverage percentage (default: 100).

.PARAMETER Force
Force rebuild of Docker images with --no-cache.

.PARAMETER DryRun
Print actions without executing them.

.EXAMPLE
scripts\windows\commands\test.ps1
scripts\windows\commands\test.ps1 -MinCoverage 80
scripts\windows\commands\test.ps1 -Force
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Intentional colored output.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DryRun',
    Justification = 'DryRun is consumed inside Invoke-Cmd via outer scope.')]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateRange(0, 100)]
    [int]$MinCoverage = 100,
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

Write-Host "🧪 platform_serial — Docker Test (min coverage: $MinCoverage%)" -ForegroundColor White -BackgroundColor DarkBlue

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "❌  Docker not found. Install Docker Desktop first."
    exit 1
}

$noCache = if ($Force) { '--no-cache' } else { '' }

Write-Step "📦 Building base image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache base"

Write-Step "📦 Building test image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache test"

Write-Step "🧪 Running test container..."
$env:MIN_COVERAGE = $MinCoverage
Invoke-Cmd "docker compose -f '$ComposeFile' run --rm test"

Write-Ok "All tests passed (min coverage: $MinCoverage%)"

