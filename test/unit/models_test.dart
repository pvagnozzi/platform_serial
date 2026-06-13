import 'package:flutter_test/flutter_test.dart';
import 'package:platform_serial/platform_serial.dart';

void main() {
  group('SerialPortInfo', () {
    test('creates port info with minimum values', () {
      final info = SerialPortInfo(
        portName: 'COM1',
        description: 'Serial Port',
        platform: 'windows',
      );

      expect(info.portName, 'COM1');
      expect(info.description, 'Serial Port');
      expect(info.vendorId, isNull);
      expect(info.productId, isNull);
      expect(info.serialNumber, isNull);
      expect(info.isOpen, false);
      expect(info.platform, 'windows');
    });

    test('creates port info with all values', () {
      final info = SerialPortInfo(
        portName: '/dev/ttyUSB0',
        description: 'CH340 Serial',
        vendorId: '1A86',
        productId: '7523',
        serialNumber: 'ABC123',
        isOpen: true,
        platform: 'linux',
      );

      expect(info.portName, '/dev/ttyUSB0');
      expect(info.description, 'CH340 Serial');
      expect(info.vendorId, '1A86');
      expect(info.productId, '7523');
      expect(info.serialNumber, 'ABC123');
      expect(info.isOpen, true);
      expect(info.platform, 'linux');
    });

    test('copyWith modifies specified values', () {
      final info = SerialPortInfo(
        portName: 'COM1',
        description: 'Serial Port',
        platform: 'windows',
      );

      final modified = info.copyWith(
        isOpen: true,
        vendorId: '1234',
      );

      expect(modified.portName, 'COM1');
      expect(modified.isOpen, true);
      expect(modified.vendorId, '1234');
      expect(modified.description, 'Serial Port');
    });

    test('operator == compares correctly', () {
      final info1 = SerialPortInfo(
        portName: 'COM1',
        description: 'Serial Port',
        platform: 'windows',
      );
      final info2 = SerialPortInfo(
        portName: 'COM1',
        description: 'Serial Port',
        platform: 'windows',
      );
      final info3 = SerialPortInfo(
        portName: 'COM2',
        description: 'Serial Port',
        platform: 'windows',
      );

      expect(info1, info2);
      expect(info1, isNot(info3));
    });

    test('toString returns a useful description', () {
      final info = SerialPortInfo(
        portName: 'COM1',
        description: 'Serial Port',
        platform: 'windows',
      );
      expect(info.toString(), contains('COM1'));
      expect(info.toString(), contains('Serial Port'));
    });
  });

  group('SerialError', () {
    test('creates error with type and message', () {
      final error = SerialError(
        type: SerialErrorType.portNotFound,
        message: 'Port not found',
      );

      expect(error.type, SerialErrorType.portNotFound);
      expect(error.message, 'Port not found');
      expect(error.stackTrace, isNull);
    });

    test('creates error with stack trace', () {
      final st = StackTrace.current;
      final error = SerialError(
        type: SerialErrorType.timeout,
        message: 'Timeout',
        stackTrace: st,
      );

      expect(error.type, SerialErrorType.timeout);
      expect(error.stackTrace, st);
    });

    test('toString includes type and message', () {
      final error = SerialError(
        type: SerialErrorType.ioError,
        message: 'I/O error',
      );

      expect(error.toString(), contains('SerialError'));
      expect(error.toString(), contains('ioError'));
      expect(error.toString(), contains('I/O error'));
    });

    test('implements Exception', () {
      final error = SerialError(
        type: SerialErrorType.unknown,
        message: 'Unknown error',
      );

      expect(error, isA<Exception>());
    });
  });

  group('SerialDataType', () {
    test('enum contains binary and text', () {
      expect(SerialDataType.binary, isNotNull);
      expect(SerialDataType.text, isNotNull);
      expect(SerialDataType.values.length, 2);
    });
  });
}
