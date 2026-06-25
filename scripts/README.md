# Development scripts

The scripts in `scripts/windows`, `scripts/linux`, and `scripts/macos` are intentionally synchronized by name and behavior.

## setup-devenv

Installs or verifies the tools needed to develop `platform_serial`:

- Git
- Flutter SDK and Dart SDK
- Android Studio and Android SDK tooling
- Oh My Posh with the `M365Princess` theme
- Shell startup integration for Oh My Posh

| Platform | Command |
| --- | --- |
| Windows | `scripts/windows/setup-devenv.ps1 -Yes` |
| Windows PowerShell prerequisite | `scripts/windows/install-powershell.bat --check` or `scripts/windows/install-powershell.bat --dry-run` |
| Linux | `scripts/linux/setup-devenv --yes` |
| macOS | `scripts/macos/setup-devenv --yes` |

Common behavior:

- idempotent: already-installed tools are skipped;
- colorful output and emoji status markers;
- `--help` / `-h` prints usage;
- `--dry-run` shows actions without changing the system and only reports when elevation would be required;
- elevation is requested or validated only around package-manager install/update actions (`winget`, `apt`/`dnf`/`pacman`/`snap`, and Homebrew bootstrap/install/cask work), not for Flutter clones or shell profile edits;
- Linux/macOS scripts refuse non-dry-run execution as root; Windows elevated runs perform only package-manager work and skip user-level Flutter/theme/profile/doctor steps until rerun non-elevated;
- `--skip-android-studio` and `--skip-oh-my-posh` opt out of optional installs.

## Windows PowerShell bootstrap

`scripts/windows/install-powershell.bat` is a Windows-only helper for machines where `pwsh` is missing or older than PowerShell 7.4.6. It supports `--check` for no-op discovery and `--dry-run` to print the `winget` install or upgrade that would run. If `winget` is unavailable, the script prints the Microsoft manual installation URL instead of attempting another installer path.
