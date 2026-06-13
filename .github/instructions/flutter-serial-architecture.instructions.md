---
description: 'Architecture and behavior constraints specific to platform_serial core and platform bridges.'
applyTo: 'lib/src/**/*.dart,android/src/main/**/*.kt,ios/Classes/**/*.swift,linux/**/*.{c,cc,h},windows/**/*.{cpp,h}'
---

# platform_serial Architecture Rules

- Keep the public package contract stable through `lib/platform_serial.dart` exports.
- Route serial I/O through `SerialPort` + `SerialPlatformInterface`; avoid bypass paths.
- Maintain event payload compatibility (`type`, `data`, `message`, optional `portName`).
- Keep error translation explicit with `SerialError` and `SerialErrorType`.
- Preserve `SerialManager` tracked-lifecycle behavior (`_openPorts`, `openPortFromConfig`, `closeAll`).
- For platform-specific updates, mirror behavior across all affected implementations (Windows/macOS/MethodChannel path).
- Avoid introducing heavy logic in stream event handlers; keep callbacks lightweight and non-blocking.
