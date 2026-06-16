import 'serial_platform_interface.dart';
import 'web_impl.dart';

SerialPlatformInterface createSerialPlatformInterface() => WebSerialImpl();
