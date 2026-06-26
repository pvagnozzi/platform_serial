# Development Scripts

Scripts are organized by platform under `scripts/windows`, `scripts/linux`, and `scripts/macos`.
Each platform folder has two subdirectories:

| Folder | Purpose |
|--------|---------|
| `setup/` | Idempotent developer environment setup (Flutter, Docker Desktop, etc.) |
| `commands/` | Run CI operations locally via Docker containers |

---

## setup/ — Developer environment setup

Installs or verifies the tools needed to develop `platform_serial`:

- Git
- Flutter SDK and Dart SDK
- Android Studio and Android SDK tooling
- **Docker Desktop** (with WSL2 + Ubuntu + Hyper-V on Windows)
- Oh My Posh with the `M365Princess` theme

| Platform | Command |
|----------|---------|
| Windows  | `scripts\windows\setup\setup-devenv.ps1 -Yes` |
| Windows PowerShell prereq | `scripts\windows\setup\install-powershell.bat --check` |
| Linux    | `scripts/linux/setup/setup-devenv --yes` |
| macOS    | `scripts/macos/setup/setup-devenv --yes` |

### Windows-specific Docker requirements

The Windows setup script (`setup-devenv.ps1`) verifies and, when run as
Administrator, automatically enables:

1. **Hyper-V** — `Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All`
2. **WSL2** — `wsl --install -d Ubuntu`
3. **Ubuntu** distribution in WSL — via `winget install Canonical.Ubuntu.2204`
4. **Docker Desktop** — `winget install Docker.DockerDesktop`

Run the script **twice** when enabling Hyper-V + WSL for the first time:
first as Administrator (package installs), then as normal user (Flutter,
theme, and profile).

### Common behavior

- **Idempotent**: already-installed tools are skipped.
- **Colorful** output with emoji status markers (✅ ⚠️ ❌).
- `--help` / `-h` prints usage with full synopsis.
- `--dry-run` shows actions without changing the system.
- `--skip-android-studio`, `--skip-docker`, `--skip-oh-my-posh` opt out of
  optional installs.

---

## commands/ — Docker container operations

Each command script builds the required Docker images (if not cached) and
runs the corresponding container. All scripts are idempotent, colorful, and
support `--dry-run`, `--force` (image rebuild), and `--help`.

| Command | Action |
|---------|--------|
| `build` / `build.ps1` | Flutter web build (JS or WASM) |
| `test` / `test.ps1` | `flutter test --coverage` + coverage gate |
| `analyze` / `analyze.ps1` | `flutter analyze` on root + example |
| `security` / `security.ps1` | Trivy + OSV-Scanner + pub outdated |
| `devcontainer` / `devcontainer.ps1` | Interactive dev shell |

### Quick start

```bash
# Linux / macOS
scripts/linux/commands/build              # web-js build
scripts/linux/commands/test               # run tests
scripts/linux/commands/analyze            # static analysis
scripts/linux/commands/security           # vulnerability scan
scripts/linux/commands/devcontainer       # interactive dev container
```

```powershell
# Windows (PowerShell)
scripts\windows\commands\build.ps1                    # web-js build
scripts\windows\commands\build.ps1 -Target web-wasm   # WASM build
scripts\windows\commands\test.ps1                     # run tests
scripts\windows\commands\analyze.ps1                  # static analysis
scripts\windows\commands\security.ps1                 # vulnerability scan
scripts\windows\commands\devcontainer.ps1             # interactive dev container
```

All Docker images are built from `containers/` — see `containers/docker-compose.yml`
and `containers/base/Dockerfile` for the shared base image.

---

## Legacy paths (backward compatibility)

The original setup scripts at `scripts/<platform>/setup-devenv` are kept as
symbolic aliases for tooling that references the old paths. Prefer the new
paths under `setup/` and `commands/` for all new work.
