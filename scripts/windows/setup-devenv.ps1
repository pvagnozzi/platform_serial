<#
.SYNOPSIS
🚀 Idempotently sets up the Windows development environment for platform_serial.

.DESCRIPTION
Installs or verifies Git, Flutter, Android Studio, Oh My Posh, the M365Princess theme,
and PowerShell profile integration. The script is safe to rerun and skips tools that
are already installed.

.PARAMETER Yes
Run without interactive confirmations.

.PARAMETER DryRun
Print actions without changing the system.

.PARAMETER FlutterDir
Flutter SDK location. Defaults to $HOME\development\flutter.

.PARAMETER SkipAndroidStudio
Do not install Android Studio.

.PARAMETER SkipOhMyPosh
Do not install or configure Oh My Posh.

.EXAMPLE
./scripts/windows/setup-devenv.ps1 -Yes
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSAvoidUsingWriteHost',
  '',
  Justification = 'This interactive setup script intentionally uses colored host output.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSReviewUnusedParameter',
  'Yes',
  Justification = 'The switch is consumed by Confirm-Setup for non-interactive setup.'
)]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [switch]$Yes,
  [switch]$DryRun,
  [string]$FlutterDir = "$HOME\development\flutter",
  [switch]$SkipAndroidStudio,
  [switch]$SkipOhMyPosh
)

$ErrorActionPreference = 'Stop'

function Write-Step($Message) { Write-Host "🚀 $Message" -ForegroundColor Cyan }
function Write-Ok($Message) { Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warn($Message) { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Assert-Administrator($Action) {
  if ($DryRun) { Write-Warn "dry-run: administrator rights would be required for $Action"; return }
  if (-not (Test-Administrator)) {
    throw "Administrator rights are required for $Action. Re-run this command from an elevated PowerShell session."
  }
}
function Invoke-Setup($Command, $Arguments, [switch]$RequiresAdministrator) {
  $rendered = "$Command $($Arguments -join ' ')"
  if ($RequiresAdministrator) { Assert-Administrator $rendered }
  if ($DryRun) { Write-Warn "dry-run: $rendered"; return }
  & $Command @Arguments
}
function Test-Command($Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Confirm-Setup($Prompt) {
  if ($Yes) { return $true }
  $answer = Read-Host "$Prompt [y/N]"
  return $answer -match '^[Yy]$'
}

Write-Host "🚀 platform_serial Windows setup" -ForegroundColor White
$IsElevatedSession = Test-Administrator
if ($IsElevatedSession) {
  Write-Warn "Running in an elevated session. Package-manager actions may run, but user-level Flutter, theme, profile, and flutter doctor steps are skipped. Re-run non-elevated afterward to finish user configuration."
}

if (Test-Command git) {
  Write-Ok "Git already installed: $(git --version)"
} elseif (Test-Command winget) {
  Write-Step "Installing Git"
  Invoke-Setup winget @('install', '--id', 'Git.Git', '--exact', '--source', 'winget', '--accept-source-agreements', '--accept-package-agreements') -RequiresAdministrator
} else {
  Write-Warn "Install Git manually: https://git-scm.com/download/win"
}

$flutterExe = Join-Path $FlutterDir 'bin\flutter.bat'
if (Test-Path $flutterExe) {
  Write-Ok "Flutter already installed at $FlutterDir"
} elseif ($IsElevatedSession -and -not $DryRun) {
  Write-Warn "Skipping Flutter SDK install in elevated session to avoid creating user files as Administrator. Re-run non-elevated to install Flutter."
} elseif (Confirm-Setup "Install Flutter SDK into $FlutterDir?") {
  $parent = Split-Path $FlutterDir -Parent
  if (-not (Test-Path $parent)) {
    if ($DryRun) { Write-Warn "dry-run: create directory $parent" } else { New-Item -ItemType Directory -Path $parent | Out-Null }
  }
  Invoke-Setup git @('clone', 'https://github.com/flutter/flutter.git', '-b', 'stable', $FlutterDir)
}

if (-not $SkipAndroidStudio) {
  $studioInstalled = Test-Path "$Env:ProgramFiles\Android\Android Studio\bin\studio64.exe"
  if ($studioInstalled) {
    Write-Ok "Android Studio already installed"
  } elseif (Test-Command winget) {
    Write-Step "Installing Android Studio"
    Invoke-Setup winget @('install', '--id', 'Google.AndroidStudio', '--exact', '--source', 'winget', '--accept-source-agreements', '--accept-package-agreements') -RequiresAdministrator
  } else {
    Write-Warn "Install Android Studio manually: https://developer.android.com/studio"
  }
}

if (-not $SkipOhMyPosh) {
  if (Test-Command oh-my-posh) {
    Write-Ok "Oh My Posh already installed"
  } elseif (Test-Command winget) {
    Write-Step "Installing Oh My Posh"
    Invoke-Setup winget @('install', 'JanDeDobbeleer.OhMyPosh', '-s', 'winget', '--accept-source-agreements', '--accept-package-agreements') -RequiresAdministrator
  } else {
    Write-Warn "Install Oh My Posh manually: https://ohmyposh.dev/docs/installation/windows"
  }

  if ($IsElevatedSession -and -not $DryRun) {
    Write-Warn "Skipping Oh My Posh theme/profile configuration in elevated session. Re-run non-elevated to configure the current user profile."
  } else {
    $themeDir = Join-Path $HOME '.poshthemes'
    $themePath = Join-Path $themeDir 'M365Princess.omp.json'
    if (-not (Test-Path $themeDir)) {
      if ($DryRun) { Write-Warn "dry-run: create directory $themeDir" } else { New-Item -ItemType Directory -Path $themeDir | Out-Null }
    }
    if (-not (Test-Path $themePath)) {
      Write-Step "Downloading M365Princess theme"
      if ($DryRun) { Write-Warn "dry-run: download $themePath" } else { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/M365Princess.omp.json' -OutFile $themePath }
    }

    if (-not (Test-Path $PROFILE)) {
      if ($DryRun) { Write-Warn "dry-run: create PowerShell profile $PROFILE" } else { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
    }
    $marker = '# platform_serial oh-my-posh'
    $profileText = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { '' }
    if ($profileText -match [regex]::Escape($marker)) {
      Write-Ok "Oh My Posh already configured in PowerShell profile"
    } else {
      $line = "`n$marker`noh-my-posh init pwsh --config '$themePath' | Invoke-Expression`n"
      if ($DryRun) { Write-Warn "dry-run: append Oh My Posh initialization to $PROFILE" } else { Add-Content -Path $PROFILE -Value $line }
    }
  }
}

if (Test-Path $flutterExe) {
  if ($IsElevatedSession -and -not $DryRun) { Write-Warn "Skipping flutter doctor in elevated session. Re-run non-elevated to check the user environment." } else { Invoke-Setup $flutterExe @('doctor') }
}
Write-Ok "Windows development environment setup complete"
