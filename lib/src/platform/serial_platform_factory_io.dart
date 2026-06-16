// coverage:ignore-file

import 'dart:io' show Platform;

import 'method_channel_serial_platform.dart';
import 'serial_platform_interface.dart';
import 'windows_impl.dart';

SerialPlatformInterface createSerialPlatformInterface() {
  if (Platform.isWindows) {
    return WindowsSerialImpl();
  }
  return MethodChannelSerialPlatformInterface();
}
