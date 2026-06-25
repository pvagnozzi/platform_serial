<#
.SYNOPSIS
🚀 Idempotently sets up the Windows development environment for platform_serial.

.DESCRIPTION
Installs or verifies: Git, Flutter, Android Studio, Docker Desktop (with WSL2 +
Ubuntu + Hyper-V validation), Oh My Posh (M365Princess theme), and PowerShell
profile integration.

.PARAMETER Yes
Run without interactive confirmations.

.PARAMETER DryRun
Print actions without changing the system.

.PARAMETER FlutterDir
Flutter SDK location. Defaults to $HOME\development\flutter.

.PARAMETER SkipAndroidStudio
Do not install Android Studio.

.PARAMETER SkipDocker
Do not install or configure Docker Desktop.

.PARAMETER SkipOhMyPosh
Do not install or configure Oh My Posh.

.EXAMPLE
scripts/windows/setup/setup-devenv.ps1 -Yes
scripts/windows/setup/setup-devenv.ps1 -DryRun
scripts/windows/setup/setup-devenv.ps1 -Yes -SkipDocker

.NOTES
Docker Desktop on Windows requires:
  - Hyper-V feature enabled (or WSL2 backend)
  - WSL2 with an Ubuntu distribution installed
  - Windows 10 version 2004+ or Windows 11
The script verifies and enables these prerequisites when run as Administrator.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSAvoidUsingWriteHost', '',
  Justification = 'This interactive setup script intentionally uses colored host output.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSReviewUnusedParameter', 'Yes',
  Justification = 'Consumed by Confirm-Setup.'
)]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [switch]$Yes,
  [switch]$DryRun,
  [string]$FlutterDir        = "$HOME\development\flutter",
  [switch]$SkipAndroidStudio,
  [switch]$SkipDocker,
  [switch]$SkipOhMyPosh
)

$ErrorActionPreference = 'Stop'

# ── Color helpers ─────────────────────────────────────────────
function Write-Step($m) { Write-Host "  $m"    -ForegroundColor Cyan   }
function Write-Ok($m)   { Write-Host "✅  $m"   -ForegroundColor Green  }
function Write-Warn($m) { Write-Host "⚠️   $m"  -ForegroundColor Yellow }
function Write-Fail($m) { Write-Host "❌  $m"   -ForegroundColor Red;
                          throw "Setup failed: $m" }

function Test-Administrator {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  ([Security.Principal.WindowsPrincipal]$id).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin($Action) {
  if ($DryRun) { Write-Warn "dry-run: admin rights would be required for $Action"; return }
  if (-not (Test-Administrator)) {
    Write-Fail "Administrator rights are required for $Action. Re-run from an elevated PowerShell."
  }
}

function Invoke-Cmd($Cmd, $Args, [switch]$RequiresAdmin) {
  $rendered = "$Cmd $($Args -join ' ')"
  if ($RequiresAdmin) { Assert-Admin $rendered }
  if ($DryRun) { Write-Warn "dry-run: $rendered"; return }
  & $Cmd @Args
}

function Test-Cmd($Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Confirm-Setup($Prompt) {
  if ($Yes) { return $true }
  ($answer = Read-Host "$Prompt [y/N]") | Out-Null
  return $answer -match '^[Yy]$'
}

# ── Header ────────────────────────────────────────────────────
Write-Host ""
Write-Host "🚀  platform_serial Windows development environment setup" `
    -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""

$IsElevated = Test-Administrator
if ($IsElevated) {
  Write-Warn "Running elevated. Package installs will run; user-level Flutter," `
    + " theme, and profile steps are skipped. Re-run non-elevated afterward."
}

# ── Git ───────────────────────────────────────────────────────
if (Test-Cmd git) {
  Write-Ok "Git: $(git --version)"
} elseif (Test-Cmd winget) {
  Write-Step "📦 Installing Git..."
  Invoke-Cmd winget @('install','--id','Git.Git','--exact',
    '--accept-source-agreements','--accept-package-agreements') -RequiresAdmin
} else {
  Write-Warn "Install Git manually: https://git-scm.com/download/win"
}

# ── Flutter ───────────────────────────────────────────────────
$flutterExe = Join-Path $FlutterDir 'bin\flutter.bat'
if (Test-Path $flutterExe) {
  Write-Ok "Flutter: already installed at $FlutterDir"
} elseif ($IsElevated -and -not $DryRun) {
  Write-Warn "Skipping Flutter install in elevated session. Re-run non-elevated."
} elseif (Confirm-Setup "Install Flutter SDK into $FlutterDir?") {
  $parent = Split-Path $FlutterDir -Parent
  if (-not (Test-Path $parent)) {
    if ($DryRun) { Write-Warn "dry-run: mkdir $parent" }
    else { New-Item -ItemType Directory -Path $parent | Out-Null }
  }
  Invoke-Cmd git @('clone','https://github.com/flutter/flutter.git',
    '-b','stable',$FlutterDir)
}

# ── Android Studio ────────────────────────────────────────────
if (-not $SkipAndroidStudio) {
  $studioExe = "$Env:ProgramFiles\Android\Android Studio\bin\studio64.exe"
  if (Test-Path $studioExe) {
    Write-Ok "Android Studio: already installed"
  } elseif (Test-Cmd winget) {
    Write-Step "🤖 Installing Android Studio..."
    Invoke-Cmd winget @('install','--id','Google.AndroidStudio','--exact',
      '--accept-source-agreements','--accept-package-agreements') -RequiresAdmin
  } else {
    Write-Warn "Install Android Studio manually: https://developer.android.com/studio"
  }
}

# ── Docker Desktop (WSL2 + Ubuntu + Hyper-V) ──────────────────
if (-not $SkipDocker) {
  Write-Step "🐳 Checking Docker Desktop prerequisites..."

  # --- Hyper-V check -------------------------------------------
  $hyperVEnabled = $false
  try {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V-All' `
                  -ErrorAction SilentlyContinue
    $hyperVEnabled = ($feature -and $feature.State -eq 'Enabled')
  } catch { $hyperVEnabled = $false }

  if ($hyperVEnabled) {
    Write-Ok "Hyper-V: enabled"
  } else {
    Write-Warn "Hyper-V is not enabled. Docker Desktop works best with Hyper-V or WSL2."
    if ($IsElevated -and (Confirm-Setup "Enable Hyper-V (requires reboot)?")) {
      if ($DryRun) {
        Write-Warn "dry-run: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All"
      } else {
        Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V-All' -All -NoRestart
        Write-Warn "Hyper-V enabled — a reboot is required to complete activation."
      }
    } elseif (-not $IsElevated) {
      Write-Warn "Re-run as Administrator to enable Hyper-V automatically."
    }
  }

  # --- WSL check -----------------------------------------------
  $wslInstalled = $false
  try {
    $wslOutput = (wsl --status 2>&1) -join ' '
    $wslInstalled = ($LASTEXITCODE -eq 0 -or $wslOutput -match 'Default Distribution')
  } catch { $wslInstalled = $false }

  if ($wslInstalled) {
    Write-Ok "WSL2: installed"
  } else {
    Write-Warn "WSL2 not detected."
    if ($IsElevated -and (Confirm-Setup "Install WSL2 with Ubuntu?")) {
      if ($DryRun) {
        Write-Warn "dry-run: wsl --install -d Ubuntu"
      } else {
        wsl --install -d Ubuntu
        Write-Ok "WSL2 + Ubuntu installation started. A reboot may be required."
      }
    } elseif (-not $IsElevated) {
      Write-Warn "Re-run as Administrator to install WSL2 + Ubuntu automatically."
      Write-Warn "Manual: wsl --install -d Ubuntu"
    }
  }

  # --- Ubuntu distribution -------------------------------------
  try {
    $ubuntuInstalled = (wsl --list --quiet 2>&1) -match 'Ubuntu'
  } catch { $ubuntuInstalled = $false }

  if ($ubuntuInstalled) {
    Write-Ok "Ubuntu (WSL): installed"
  } else {
    Write-Warn "Ubuntu WSL distribution not found."
    if (Test-Cmd winget -and (Confirm-Setup "Install Ubuntu via winget?")) {
      Invoke-Cmd winget @('install','--id','Canonical.Ubuntu.2204','--exact',
        '--accept-source-agreements','--accept-package-agreements')
      Write-Ok "Ubuntu installed. Launch it from Start to complete initial setup."
    } else {
      Write-Warn "Install Ubuntu manually from the Microsoft Store."
    }
  }

  # --- Docker Desktop ------------------------------------------
  if (Test-Cmd docker) {
    Write-Ok "Docker: $(docker --version)"
  } else {
    Write-Step "🐳 Installing Docker Desktop..."
    if (Test-Cmd winget) {
      Invoke-Cmd winget @('install','--id','Docker.DockerDesktop','--exact',
        '--accept-source-agreements','--accept-package-agreements') -RequiresAdmin
      Write-Ok "Docker Desktop installed. Start it from the Start Menu."
      Write-Warn "After first launch: Settings → General → Use WSL 2 based engine ✅"
    } else {
      Write-Warn "Install Docker Desktop manually: https://docs.docker.com/desktop/windows/install/"
    }
  }
}

# ── Oh My Posh ────────────────────────────────────────────────
if (-not $SkipOhMyPosh) {
  if (Test-Cmd oh-my-posh) {
    Write-Ok "Oh My Posh: $(oh-my-posh version 2>$null)"
  } elseif (Test-Cmd winget) {
    Write-Step "🎨 Installing Oh My Posh..."
    Invoke-Cmd winget @('install','JanDeDobbeleer.OhMyPosh','-s','winget',
      '--accept-source-agreements','--accept-package-agreements') -RequiresAdmin
  } else {
    Write-Warn "Install Oh My Posh manually: https://ohmyposh.dev/docs/installation/windows"
  }

  if (-not $IsElevated -or $DryRun) {
    $themeDir  = Join-Path $HOME '.poshthemes'
    $themePath = Join-Path $themeDir 'M365Princess.omp.json'
    if (-not (Test-Path $themeDir)) {
      if ($DryRun) { Write-Warn "dry-run: mkdir $themeDir" }
      else { New-Item -ItemType Directory -Path $themeDir | Out-Null }
    }
    if (-not (Test-Path $themePath)) {
      Write-Step "📥 Downloading M365Princess theme..."
      if ($DryRun) { Write-Warn "dry-run: download $themePath" }
      else {
        Invoke-WebRequest `
          -Uri 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/M365Princess.omp.json' `
          -OutFile $themePath
      }
    } else {
      Write-Ok "M365Princess theme: already downloaded"
    }

    if (-not (Test-Path $PROFILE)) {
      if ($DryRun) { Write-Warn "dry-run: create $PROFILE" }
      else { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
    }
    $marker      = '# platform_serial oh-my-posh'
    $profileText = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { '' }
    if ($profileText -match [regex]::Escape($marker)) {
      Write-Ok "Oh My Posh: already configured in PowerShell profile"
    } else {
      $line = "`n$marker`noh-my-posh init pwsh --config '$themePath' | Invoke-Expression`n"
      if ($DryRun) { Write-Warn "dry-run: append Oh My Posh init to $PROFILE" }
      else { Add-Content -Path $PROFILE -Value $line }
      Write-Ok "Oh My Posh configured in PowerShell profile"
    }
  } else {
    Write-Warn "Skipping Oh My Posh theme/profile setup in elevated session. Re-run non-elevated."
  }
}

# ── Flutter doctor ────────────────────────────────────────────
Write-Host ""
if (Test-Path $flutterExe) {
  if ($IsElevated -and -not $DryRun) {
    Write-Warn "Skipping flutter doctor in elevated session. Re-run non-elevated."
  } else {
    Invoke-Cmd $flutterExe @('doctor')
  }
}

# ── Summary ───────────────────────────────────────────────────
Write-Host ""
Write-Ok "Windows development environment setup complete!"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    flutter pub get"
Write-Host "    flutter analyze --fatal-infos --fatal-warnings"
Write-Host "    flutter test --coverage"
Write-Host "    scripts\windows\commands\build.ps1     <- Docker build"
Write-Host "    scripts\windows\commands\test.ps1      <- Docker test"
Write-Host "    scripts\windows\commands\security.ps1  <- Docker security scan"
