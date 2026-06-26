<#
.SYNOPSIS
🔒 Runs platform_serial vulnerability and security scan inside Docker.

.DESCRIPTION
Idempotent script. Builds the base image and the security image (with
--no-cache if -Force is set), then runs Trivy filesystem scan, Trivy
config/IaC scan, OSV-Scanner dependency audit, and dart pub outdated.
Reports are saved to ./security-reports/.

.PARAMETER NoFail
Report findings without exiting with a non-zero code for HIGH/CRITICAL.

.PARAMETER Force
Force rebuild of Docker images with --no-cache.

.PARAMETER DryRun
Print actions without executing them.

.EXAMPLE
scripts\windows\commands\security.ps1
scripts\windows\commands\security.ps1 -NoFail
scripts\windows\commands\security.ps1 -Force
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Intentional colored output.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DryRun',
    Justification = 'DryRun is consumed inside Invoke-Cmd via outer scope.')]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$NoFail,
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

Write-Host "🔒 platform_serial — Security Scan" -ForegroundColor White -BackgroundColor DarkBlue

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "❌  Docker not found. Install Docker Desktop first."
    exit 1
}

$noCache = if ($Force) { '--no-cache' } else { '' }
$failOnHigh = if ($NoFail) { 'false' }      else { 'true' }

Write-Step "📦 Building base image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache base"

Write-Step "📦 Building security image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache security"

Write-Step "🔒 Running security container..."
$env:FAIL_ON_HIGH = $failOnHigh
Invoke-Cmd "docker compose -f '$ComposeFile' run --rm security"

Write-Ok "Security scan complete — check security-reports/ for detailed findings"

