<#
.SYNOPSIS
🧑‍💻 Starts the platform_serial development container.

.DESCRIPTION
Builds and launches the full devcontainer image with an interactive shell.
The Docker socket is mounted for sibling container operations.
Use this as a local equivalent to VS Code Dev Containers.

.PARAMETER Force
Force rebuild of the devcontainer image.

.PARAMETER DryRun
Print actions without executing them.

.PARAMETER Command
Optional command to run inside the container instead of an interactive shell.

.EXAMPLE
scripts/windows/commands/devcontainer.ps1
scripts/windows/commands/devcontainer.ps1 -Force
scripts/windows/commands/devcontainer.ps1 -Command "flutter test"
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost','',Justification='Intentional colored output.')]
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [switch]$Force,
  [switch]$DryRun,
  [string]$Command = '',
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

Write-Host "🧑‍💻 platform_serial — DevContainer" -ForegroundColor White -BackgroundColor DarkBlue

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Error "❌  Docker not found. Install Docker Desktop first."
  exit 1
}

$noCache = if ($Force) { '--no-cache' } else { '' }

Write-Step "📦 Building devcontainer image..."
Invoke-Cmd "docker compose -f '$ComposeFile' build $noCache devcontainer"

if ($Command) {
  Write-Step "▶️  Running: $Command"
  Invoke-Cmd "docker compose -f '$ComposeFile' run --rm devcontainer $Command"
} else {
  Write-Step "🐚 Starting interactive shell..."
  Invoke-Cmd "docker compose -f '$ComposeFile' run --rm --service-ports devcontainer"
}

Write-Ok "DevContainer session ended"
