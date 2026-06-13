import 'package:flutter_test/flutter_test.dart';
import 'package:platform_serial/platform_serial.dart';

void main() {
  group('SerialConfig', () {
    test('creates config with default values', () {
      final config = SerialConfig(portName: 'COM1');

      expect(config.portName, 'COM1');
      expect(config.baudRate, 9600);
      expect(config.dataBits, 8);
      expect(config.stopBits, SerialStopBits.one);
      expect(config.parity, SerialParity.none);
      expect(config.flowControl, SerialFlowControl.none);
      expect(config.readTimeout, const Duration(seconds: 5));
      expect(config.writeTimeout, const Duration(seconds: 5));
    });

    test('creates config with custom values', () {
      final config = SerialConfig(
        portName: '/dev/ttyUSB0',
        baudRate: 115200,
        dataBits: 7,
        stopBits: SerialStopBits.two,
        parity: SerialParity.even,
        flowControl: SerialFlowControl.rtscts,
        readTimeout: const Duration(seconds: 10),
        writeTimeout: const Duration(seconds: 10),
      );

      expect(config.portName, '/dev/ttyUSB0');
      expect(config.baudRate, 115200);
      expect(config.dataBits, 7);
      expect(config.stopBits, SerialStopBits.two);
      expect(config.parity, SerialParity.even);
      expect(config.flowControl, SerialFlowControl.rtscts);
      expect(config.readTimeout, const Duration(seconds: 10));
      expect(config.writeTimeout, const Duration(seconds: 10));
    });

    test('rejects dataBits < 5', () {
      expect(
        () => SerialConfig(portName: 'COM1', dataBits: 4),
        throwsAssertionError,
      );
    });

    test('rejects dataBits > 8', () {
      expect(
        () => SerialConfig(portName: 'COM1', dataBits: 9),
        throwsAssertionError,
      );
    });

    test('copyWith modifies specified values', () {
      final config = SerialConfig(portName: 'COM1');
      final modified = config.copyWith(
        baudRate: 115200,
        dataBits: 7,
      );

      expect(modified.portName, 'COM1');
      expect(modified.baudRate, 115200);
      expect(modified.dataBits, 7);
      expect(modified.stopBits, SerialStopBits.one);
    });

    test('operator == compares correctly', () {
      final config1 = SerialConfig(portName: 'COM1', baudRate: 9600);
      final config2 = SerialConfig(portName: 'COM1', baudRate: 9600);
      final config3 = SerialConfig(portName: 'COM1', baudRate: 115200);

      expect(config1, config2);
      expect(config1, isNot(config3));
    });

    test('toString returns a useful description', () {
      final config = SerialConfig(portName: 'COM1');
      expect(
        config.toString(),
        contains('COM1'),
      );
    });
  });
}
