## 0.2.1

### Repository Restructure: examples/, containers/, and command scripts

#### Changed

- **`example/` → `examples/flutter_serial_monitor/`**: the example app now
  lives under the `examples/` folder with a descriptive name. Package renamed
  from `platform_serial_example` to `flutter_serial_monitor`. Plugin path
  updated to `../..`.
- **Scripts reorganized**: setup scripts moved to `scripts/<platform>/setup/`;
  new per-platform command scripts added under `scripts/<platform>/commands/`.
- All setup scripts updated to include **Docker Desktop** installation
  (Linux: Docker Engine via apt; macOS: via Homebrew cask; Windows: via
  winget with automatic Hyper-V + WSL2 + Ubuntu prerequisite verification).
- CI workflows (`test-pr.yml`) updated to reference the new path
  `examples/flutter_serial_monitor`.

#### Added

- **`containers/`** directory with five Docker images sharing a single base:
  - `containers/base/Dockerfile` — Flutter + Dart foundation (shared layer)
  - `containers/build/Dockerfile` — multi-stage: web-js \| web-wasm \| pubdry
  - `containers/test/Dockerfile` — `flutter test --coverage` + coverage gate
  - `containers/analyze/Dockerfile` — `flutter analyze` on root + example
  - `containers/security/Dockerfile` — Trivy FS, Trivy config, OSV-Scanner,
    `pub outdated` (multi-stage: installs scanners from upstream)
  - `containers/devcontainer/Dockerfile` — full dev env with Docker CLI,
    Trivy, Linux desktop toolchain, non-root `vscode` user
  - `containers/docker-compose.yml` — orchestrates all services
  - `containers/README.md` — container guide with architecture diagram
- **`containers/devcontainer/devcontainer.json`** and
  **`.devcontainer/devcontainer.json`** — VS Code Dev Containers support.
- **Command scripts** (`scripts/<platform>/commands/`) for each container:
  `build`, `test`, `analyze`, `security`, `devcontainer`.
  All scripts are idempotent, colorful (ANSI), emoji-decorated, support
  `--dry-run`, `--force`, and `--help`/synopsis.
- **Windows setup improvements** (`scripts/windows/setup/setup-devenv.ps1`):
  - Checks and enables **Hyper-V** (Admin required).
  - Checks and installs **WSL2** with **Ubuntu** (`wsl --install -d Ubuntu`).
  - Installs **Docker Desktop** via winget.
- **macOS setup improvements**: installs Docker Desktop via
  `brew install --cask docker`.
- **Linux setup improvements**: installs Docker Engine via apt repository
  and adds the user to the `docker` group.

#### Verified

- `flutter analyze --fatal-infos --fatal-warnings` (root + example)
- `flutter test --coverage` → 95/95 passed
- `dart run tool/coverage_gate.dart --lcov coverage/lcov.info --min-lines 100`
  → 100% (269/269)

---

## 0.2.0

### Full Web & WASM Support

#### Added

- **WASM-compatible conditional import**: changed factory selector from
  `dart.library.html` (deprecated) to `dart.library.js_interop`, enabling
  compilation to both Flutter Web JS and Flutter Web WASM targets.
- **Proper web plugin registrar** in `platform_serial_web.dart`: now imports
  `flutter_web_plugins` and declares `registerWith(Registrar)` correctly.
- `flutter_web_plugins` (Flutter SDK) added to plugin dependencies.
- **Web-aware example UI**: on web the port dropdown is replaced by a
  "Select & Connect" button that triggers the browser's native port picker
  (`navigator.serial.requestPort()`), which requires a user gesture.
- **Web Serial API info banner** in the example: reminds users of the
  Chrome/Edge 89+ and HTTPS requirements.
- **`SerialTerminalController.isWeb`** and **`openWebPort()`** for clean
  platform-specific logic without `if (kIsWeb)` scattered in the UI.
- **VS Code launch configurations** for all platforms in
  `example/.vscode/launch.json` (Windows, Linux, macOS, Android, iOS,
  Chrome JS, Chrome WASM, Web Server JS, Web Server WASM).
- **IntelliJ / Android Studio run configurations** in
  `example/.idea/runConfigurations/`.
- **`test/unit/web_platform_test.dart`**: unit tests for web platform
  factory, conditional import selection, and stub behaviour.
- **`test/unit/mocks.dart`**: shared mock definitions for `SerialPlatformInterface`.
- **`doc/WEB_WASM.md`**: comprehensive Web & WASM guide with browser
  requirements, API flow diagram, limitation table, build commands,
  and launch configuration reference.

#### Changed

- `pubspec.yaml` plugin registrar now correctly references
  `flutter_web_plugins` from the Flutter SDK.
- Example `web/index.html` updated with proper lang, viewport, description,
  and Web Serial API usage notes.
- Example localization (`AppLocalizations`) extended with
  `selectWebPort`, `webSerialNotice`, and `webSerialUnsupported` strings
  (EN, IT, FR, KO; other locales fall back to EN).
- Version bumped to `0.2.0`.

#### Verified

- `flutter analyze --fatal-infos --fatal-warnings`
- `flutter test --coverage`
- `dart run tool/coverage_gate.dart --lcov coverage/lcov.info --min-lines 100`

---

## 0.1.3

### Web Support and Copilot Governance Expansion

#### Added

- Flutter Web support through a Web Serial wrapper implementation with runtime-safe platform factory resolution.
- New Copilot agents and skills for security/vulnerability auditing, performance optimization, and test generation (unit/integration/e2e/good-bad-edge paths).
- Extended MCP server configuration for fetch, memory, sqlite, sequential thinking, and browser automation use cases.

#### Changed

- Refactored platform dispatch to separate IO and Web factories while preserving typed `SerialError` behavior.
- Updated repository metadata and plugin configuration in `pubspec.yaml` for web plugin registration.
- Updated README platform matrix and architecture diagram to include web support constraints.

#### Verified

- `flutter analyze --fatal-infos --fatal-warnings`
- `flutter test --coverage`
- `dart run tool/coverage_gate.dart --lcov coverage/lcov.info --min-lines 100`
- `flutter build windows --debug` (example app)

## 0.1.2

### Pub.dev Quality Cleanup

#### Changed

- Shortened the package description to satisfy pub.dev search-result metadata guidance.
- Updated the documentation URL to the reachable `dev` branch documentation path.
- Upgraded Flutter lint rules in the root package and example app to remove analyzer/lint warnings.
- Added `.pubignore` exclusions for local runtime, coverage, build, and generated ephemeral artifacts.

#### Verified

- `flutter analyze --fatal-infos --fatal-warnings`
- `flutter test --coverage`
- `dart run tool/coverage_gate.dart --lcov coverage/lcov.info --min-lines 100`
- `flutter pub publish --dry-run`

## 0.1.1

### Professional Hardening and Control Signals

#### Added

- Public `SerialControlSignals` model for RTS, CTS, DTR, DSR and DCD status snapshots.
- `SerialPort.getControlSignals()` and `SerialPort.getCts()` APIs.
- Linux MethodChannel support for reading control signals and setting DTR/RTS through the existing native `getControlSignals` and `setControlSignals` handlers.
- Windows FFI support for reading CTS/DSR/DCD status and tracked DTR/RTS output state.
- 100% line-coverage gate for the configured test coverage scope.
- Professional GitFlow branch-protection ruleset, release manager agent, Copilot quality gate skill, repository templates and cross-platform development setup scripts.

#### Changed

- Release publishing now targets pub.dev trusted publishing/OIDC and creates GitHub tags/releases only after successful publish.
- Documentation now includes Mermaid diagrams for architecture, quality gate, GitFlow and release workflows.

#### Verified

- `flutter analyze --fatal-infos --fatal-warnings`
- `flutter test --coverage`
- `dart run tool/coverage_gate.dart --lcov coverage/lcov.info --min-lines 100`
- `flutter pub publish --dry-run`

## 0.1.0

### First Release - Core Functionality

#### Added

- Unified `SerialPort` interface for serial communication
- `SerialManager` for centralized port management
- Support for synchronous and asynchronous reading
- Support for binary and textual data
- Data streams for continuous asynchronous reading
- Flexible configuration (baud rate, data bits, stop bits, parity, flow control)
- Configurable timeouts for read and write operations
- Robust error handling with specific error types:
  - `portNotFound`
  - `portAlreadyOpen`
  - `portClosed`
  - `configurationError`
  - `timeout`
  - `platformUnavailable`
  - `ioError`
  - `permissionDenied`
  - `bufferOverflow`
  - `unknown`
- Example app with language selection (15 languages with flags 🇬🇧 🇮🇹 🇫🇷 etc.)
- Light/Dark/System theme support
- Git Flow workflow with GitVersion configuration
- GitHub Actions CI/CD workflows:
  - Automated testing on PR
  - Automated pub.dev publishing with Google OAuth

#### Supported Platforms

- Windows (FFI implementation)
- Linux (FFI implementation)
- macOS (FFI implementation)
- Android (platform channel + OTG support)
- iOS (platform channel + OTG support)

#### Port Information

- List of available ports
- Device details (vendor ID, product ID, serial number)
- Port status (open/closed)

#### Testing

- Unit tests for core logic
- Integration tests for platform-specific behavior
- E2E tests with happy path, failure path, and edge cases
- Mock serial ports for testing

#### Documentation

- Comprehensive architecture documentation
- Platform-specific implementation guides
- Git Flow and release process documentation
- Google OAuth setup for automated publishing

#### Notes

- First stable release - production-ready
- Ready for use on all supported platforms
