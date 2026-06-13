<!-- Copyright (c) 2026 Piergiorgio Vagnozzi. -->
<!-- Licensed under the MIT License. -->
# 📡 platform_serial

[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=for-the-badge)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android%20%7C%20iOS-6f42c1?style=for-the-badge)](#platform-support)
[![License](https://img.shields.io/badge/license-MIT-2ea44f?style=for-the-badge)](LICENSE)

> 🔌 **Professional cross-platform serial communication plugin for Flutter** with sync/async I/O, streaming, typed errors, and native bridge support.

---

## ✨ Features

- Unified API (`SerialManager`, `SerialPort`) across supported platforms
- Binary and text communication (`read`, `readSync`, `readUntil`, `write`, `writeText`)
- Real-time streams (`dataStream`, `textStream`, `errorStream`)
- Typed error model (`SerialError`, `SerialErrorType`)
- Unit, integration and e2e tests
- Professional Copilot assets in `.github/` (instructions, agents, skills, hooks, MCP, collections)

---

## Platform Support

| Platform | Implementation | Status |
|---|---|---|
| Windows | FFI (`platform_serial.dll`) | ✅ |
| macOS | FFI (`DynamicLibrary.process`) | ✅ |
| Linux | MethodChannel | ✅ |
| Android | MethodChannel | ✅ |
| iOS | MethodChannel | ✅ |
| Web | Not supported | ❌ |

---

## Quick Start

```dart
import 'package:platform_serial/platform_serial.dart';

final manager = SerialManager();
final ports = await manager.getAvailablePorts();

final port = await manager.openPort('COM3', baudRate: 115200, dataBits: 8);
await port.writeText('AT\r\n');
final response = await port.readUntil('\n');
await manager.closePort('COM3');
```

---

## Example Application

This repository includes a full professional example app in `example/`:

- serial port selection and refresh
- configurable serial parameters (baud rate, data bits, stop bits, parity, flow control, read/write timeout)
- open/close connection lifecycle
- bidirectional serial terminal (read + write)
- themed UI with color-coded terminal events
- splash screen with logo
- about dialog with copyright and licenses
- multilingual UI (EN, FR, PT, ES, IT, DE, NL, RU, EL, TR, AR, HE, ZH, JA, KO)

Run it:

```bash
cd example
flutter pub get
flutter run
```

---

## Build, Lint and Test

```bash
flutter pub get
flutter analyze
flutter test
```

Example app tests:

```bash
cd example
flutter test
```

---

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE).
