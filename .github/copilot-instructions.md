# Copilot Instructions for `platform_serial`

## Build, test, and lint commands

Run commands from the repository root.

```bash
flutter pub get
flutter analyze
flutter test
```

Targeted tests:

```bash
# Single test file
flutter test test/unit/serial_port_test.dart

# Single test case name inside a file
flutter test test/unit/serial_port_test.dart --plain-name "reads data synchronously"
```

Platform builds (documented in `docs/INDEX.md`):

```bash
flutter build windows --verbose
flutter build linux --verbose
flutter build macos --verbose
flutter build apk --debug
flutter build ios --debug
```

## High-level architecture

- Public API is exported from `lib/platform_serial.dart`; core runtime logic is centered on `SerialManager` and `SerialPort`.
- `SerialManager` (`lib/src/serial_manager.dart`) is a singleton-style registry of open ports (`Map<String, SerialPort>`), with `openPort/openPortFromConfig`, `closePort`, and `closeAll`.
- `SerialPort` (`lib/src/serial_port.dart`) implements `SerialPortInterface`, delegates all I/O to `SerialPlatformInterface`, and translates platform events into:
  - `dataStream` (`Uint8List`)
  - `textStream` (`String`)
  - `errorStream` (`SerialError`)
- `SerialPlatformInterface` (`lib/src/platform/serial_platform_interface.dart`) resolves implementations by platform:
  - Windows: `WindowsSerialImpl` (FFI to `platform_serial.dll`)
  - Non-Windows: `MethodChannelSerialPlatformInterface`
    - macOS calls `MacOSSerialImpl` (FFI via `DynamicLibrary.process()`)
    - iOS calls `IOSSerialImpl` (iOS-specific method/event channels)
    - Android/Linux use shared method/event channels (`dev.flutter/platform_serial`, `dev.flutter/platform_serial_events`)
- Native implementations live under `windows/`, `linux/`, `macos/`, `android/`, and `ios/` and are wired through the above platform layer.

## Key conventions in this repository

- Use `SerialError` + `SerialErrorType` as the cross-platform error contract; surface typed serial errors rather than raw platform exceptions.
- Event payload contract is map-based and string-typed (`type`, `data`, `message`, optional `portName`). `SerialPort` expects:
  - data event: `{'type': 'data', 'data': List<int>}`
  - error event: `{'type': 'error', 'message': String}`
- For testability, inject `SerialPlatformInterface` into `SerialPort` and `SerialManager`; tests rely on this heavily with `mocktail`.
- `SerialManager` is shared state (singleton factory). Passing `platform:` to `SerialManager(...)` replaces the platform on the shared instance; keep this in mind when adding tests or global initialization.
- `createPort()` intentionally creates an unopened `SerialPort`; `openPort*` methods are responsible for tracking lifecycle in `_openPorts`.
- Stream handling is broadcast-based and expected to be non-blocking; platform listeners should emit small map events and avoid doing heavy work on the event thread.

## Optimization-focused Copilot workflow

- For quick iteration on Dart changes, default to:
  1. `flutter analyze`
  2. `flutter test test/unit/<target_file>_test.dart`
  3. `flutter test` only after targeted checks are green
- For behavior regressions in stream/I-O flows, run focused suites first:
  - `flutter test test/integration/serial_communication_test.dart`
  - `flutter test test/e2e/good_bad_edge_cases_test.dart`
- Treat these as performance-sensitive paths when editing:
  - Windows polling loop and chunking in `lib/src/platform/windows_impl.dart`
  - macOS polling timer/readability checks in `lib/src/platform/macos_impl.dart`
  - Event translation path in `lib/src/serial_port.dart` (`_startEventListener`)
- Keep event payloads compact and stable (`type`, `data`, `message`, `portName`) to avoid extra parsing overhead and cross-platform drift.
- When asking Copilot for changes, be explicit about:
  - target layer (`lib/src/serial_port.dart`, `serial_manager.dart`, or `lib/src/platform/*`)
  - platform scope (Windows only vs MethodChannel path vs all)
  - required validation command (single-file test vs integration vs full suite)

## Repository Copilot assets

- Instructions: `.github/instructions/*.instructions.md`
- Agents: `.github/agents/*.agent.md`
- Skills: `.github/skills/*/SKILL.md`
- MCP config: `.github/mcp-config.json`
- Hooks config: `hooks.json` and `.github/hooks/**`
- Collections manifest: `.github/collections/awesome-copilot-mobile-stack.json`
