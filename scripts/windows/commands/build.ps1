<#
.SYNOPSIS
🏗️  Builds the platform_serial Flutter web output using Docker.

.DESCRIPTION
Idempotent script. Builds the base image and the builder image (with
--no-cache if -Force is set), then runs the builder container.
Supports JS (default), WASM, and pub.dev dry-run targets.

.PARAMETER Target
Build target: web-js (default) | web-wasm | pubdry.

.PARAMETER Force
Force rebuild of Docker images with --no-cache.

.PARAMETER DryRun
Print actions without executing them.

.EXAMPLE
scripts\windows\commands\build.ps1
scripts\windows\commands\build.ps1 -Target web-wasm
scripts\windows\commands\build.ps1 -Target pubdry -Force
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Intentional colored output.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DryRun',
    Justification = 'DryRun is consumed inside Invoke-Cmd via outer scope.')]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('web-js', 'web-wasm', 'pubdry')]
    [string]$Target = 'web-js',
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Help
)
$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot    = Resolve-Path (Join-Path $ScriptDir '..\..\..') | Select-Object -ExpandProperty Path
$ComposeFile = Join-Path $RepoRoot 'containers\docker-compose.yml'

function Write-Step($m) { Write-Host "  $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "✅  $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "⚠️   $m" -ForegroundColor Yellow }
function Invoke-Cmd {
    param([string]$Cmd)
    if ($DryRun) { Write-Warn "dry-run: $Cmd" } else { Invoke-Expression $Cmd }
}

if ($Help) { Get-Help $MyInvocation.MyCommand.Path -Detailed; exit 0 }

Write-Host "🏗️  platform_serial — Docker Build (target: $Target)" -ForegroundColor White -BackgroundColor DarkBlue

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "❌  Docker not found. Install Docker Desktop first."
    exit 1
}

$noCache = if ($Force) { '--no-cache' } else { '' }

Write-Step "📦 Building base image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache base"

Write-Step "📦 Building builder image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache builder"

Write-Step "🏗️  Running builder (target: $Target)..."
$env:BUILD_TARGET = $Target
Invoke-Cmd "docker compose -f '$ComposeFile' run --rm builder"

Write-Ok "Build complete (target: $Target)"
