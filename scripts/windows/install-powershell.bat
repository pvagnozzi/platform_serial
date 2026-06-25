@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Installs or updates PowerShell 7 for platform_serial Windows development.
rem Minimum supported PowerShell version: 7.4.6.
set "MIN_PWSH_VERSION=7.4.6"
set "DRY_RUN=0"
set "CHECK_ONLY=0"

:parse_args
if "%~1"=="" goto :after_args
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="--dry-run" set "DRY_RUN=1"& shift & goto :parse_args
if /I "%~1"=="/dry-run" set "DRY_RUN=1"& shift & goto :parse_args
if /I "%~1"=="--check" set "CHECK_ONLY=1"& shift & goto :parse_args
if /I "%~1"=="/check" set "CHECK_ONLY=1"& shift & goto :parse_args
echo Unknown option: %~1
echo.
goto :usage

:usage
echo platform_serial PowerShell installer/updater
echo.
echo Usage:
echo   scripts\windows\install-powershell.bat [--check] [--dry-run]
echo.
echo Options:
echo   --check     Discover installed pwsh and exit without installing.
echo   --dry-run   Print install/update actions without changing the system.
echo   --help      Show this help.
echo.
echo Ensures PowerShell %MIN_PWSH_VERSION% or newer is available as pwsh.
exit /b 0

:after_args
call :find_pwsh
if defined PWSH_EXE (
  for /f "delims=" %%V in ('pwsh -NoProfile -NoLogo -Command "$PSVersionTable.PSVersion.ToString()" 2^>nul') do set "PWSH_VERSION=%%V"
  if defined PWSH_VERSION (
    pwsh -NoProfile -NoLogo -Command "$v = $PSVersionTable.PSVersion; if ($v -lt [version]'%MIN_PWSH_VERSION%') { exit 1 }; exit 0" >nul 2>nul
    if not errorlevel 1 (
      echo PowerShell !PWSH_VERSION! already installed: %PWSH_EXE%
      exit /b 0
    )
    echo PowerShell !PWSH_VERSION! is older than required %MIN_PWSH_VERSION%.
    set "ACTION=upgrade"
  ) else (
    echo Found pwsh but could not determine its version: %PWSH_EXE%
    set "ACTION=upgrade"
  )
) else (
  echo PowerShell pwsh was not found.
  set "ACTION=install"
)

if "%CHECK_ONLY%"=="1" (
  echo Check only: %ACTION% would be required for Microsoft.PowerShell.
  exit /b 1
)

where winget >nul 2>nul
if errorlevel 1 (
  echo winget is not available. Install PowerShell manually from:
  echo   https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows
  exit /b 1
)

if "%DRY_RUN%"=="1" (
  echo dry-run: administrator rights would be required to %ACTION% Microsoft.PowerShell with winget.
  echo dry-run: winget %ACTION% --id Microsoft.PowerShell --exact --source winget --accept-source-agreements --accept-package-agreements
  exit /b 0
)

call :require_admin "%ACTION% Microsoft.PowerShell with winget"
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="upgrade" (
  winget upgrade --id Microsoft.PowerShell --exact --source winget --accept-source-agreements --accept-package-agreements
) else (
  winget install --id Microsoft.PowerShell --exact --source winget --accept-source-agreements --accept-package-agreements
)
if errorlevel 1 exit /b %ERRORLEVEL%

echo PowerShell %ACTION% complete. Open a new terminal and run: pwsh --version
exit /b 0

:find_pwsh
for /f "delims=" %%P in ('where pwsh 2^>nul') do (
  set "PWSH_EXE=%%P"
  goto :eof
)
goto :eof

:require_admin
net session >nul 2>nul
if not errorlevel 1 exit /b 0
echo Administrator rights are required to %~1.
echo Re-run this script from an elevated Command Prompt or PowerShell session.
exit /b 1
