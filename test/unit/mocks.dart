// Copyright (c) 2026 Piergiorgio Vagnozzi.
// Licensed under the MIT License.

// Shared mock definitions reused across test files.

import 'package:mocktail/mocktail.dart';
import 'package:platform_serial/platform_serial.dart';

/// Mock for [SerialPlatformInterface] — use in unit tests that need to
/// exercise [SerialManager] or [SerialPort] without real hardware.
class MockSerialPlatformInterface extends Mock
    implements SerialPlatformInterface {}
