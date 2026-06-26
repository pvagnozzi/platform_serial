// Copyright (c) 2026 Piergiorgio Vagnozzi.
// Licensed under the MIT License.

/// Web plugin registrar for platform_serial.
///
/// This file is the entry point for the Flutter Web plugin system.
/// The actual Web Serial API implementation is in
/// `src/platform/web_impl.dart` and is selected automatically via
/// conditional imports using `dart.library.js_interop`.
///
/// Browser requirements:
/// - Chrome/Edge 89+ (Web Serial API support)
/// - HTTPS or localhost (required by Web Serial API)
/// - User gesture for `requestPort()` (browser security policy)
library;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web plugin class registered by the Flutter plugin system.
///
/// The [registerWith] method is called automatically by Flutter when the
/// plugin runs on the web platform.
class PlatformSerialWeb {
  /// Registers this plugin implementation with the web plugin registrar.
  ///
  /// Flutter calls this automatically; there is no need to invoke it manually.
  static void registerWith(Registrar registrar) {
    // The platform implementation is selected at compile time via conditional
    // imports (dart.library.js_interop → serial_platform_factory_web.dart →
    // WebSerialImpl). No MethodChannel registration is needed because
    // SerialPlatformInterface uses a factory constructor, not a method channel.
  }
}
