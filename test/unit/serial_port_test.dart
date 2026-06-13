import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:platform_serial/platform_serial.dart';
import 'package:mocktail/mocktail.dart';

class MockSerialPlatformInterface extends Mock
    implements SerialPlatformInterface {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      SerialConfig(portName: 'COM1'),
    );
    registerFallbackValue(Uint8List(0));
  });

  group('SerialPort', () {
    late MockSerialPlatformInterface mockPlatform;
    late SerialPort port;

    setUp(() {
      mockPlatform = MockSerialPlatformInterface();
      port = SerialPort(platform: mockPlatform);
    });

    tearDown(() async {
      if (port.isOpen) {
        try {
          await port.dispose();
        } catch (_) {}
      }
    });

    test('initially the port is closed', () {
      expect(port.isOpen, false);
    });

    test('opens port with configuration', () async {
      final config = SerialConfig(portName: 'COM1');
      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);

      expect(port.isOpen, true);
      expect(port.config, config);
      verify(() => mockPlatform.openPort(config)).called(1);
    });

    test('throws when the port is already open', () async {
      final config = SerialConfig(portName: 'COM1');
      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);

      expect(
        () => port.open(config),
        throwsA(isA<SerialError>().having(
          (e) => e.type,
          'type',
          SerialErrorType.portAlreadyOpen,
        )),
      );
    });

    test('closes an open port', () async {
      final config = SerialConfig(portName: 'COM1');
      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.closePort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);
      expect(port.isOpen, true);

      await port.close();
      expect(port.isOpen, false);
      verify(() => mockPlatform.closePort('COM1')).called(1);
    });

    test('throws when closing a port that is not open', () async {
      expect(
        () => port.close(),
        throwsA(isA<SerialError>().having(
          (e) => e.type,
          'type',
          SerialErrorType.portClosed,
        )),
      );
    });

    test('writes data to the port', () async {
      final config = SerialConfig(portName: 'COM1');
      final data = Uint8List.fromList([1, 2, 3]);

      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.writeData(any(), any()))
          .thenAnswer((_) async => 3);
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);
      final bytesWritten = await port.write(data);

      expect(bytesWritten, 3);
      verify(() => mockPlatform.writeData('COM1', data)).called(1);
    });

    test('writes text to the port', () async {
      final config = SerialConfig(portName: 'COM1');
      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.writeData(any(), any()))
          .thenAnswer((_) async => 11);
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);
      final bytesWritten = await port.writeText('Hello World');

      expect(bytesWritten, 11);
    });

    test('throws when writing to a closed port', () async {
      final data = Uint8List.fromList([1, 2, 3]);

      expect(
        () => port.write(data),
        throwsA(isA<SerialError>().having(
          (e) => e.type,
          'type',
          SerialErrorType.portClosed,
        )),
      );
    });

    test('reads data synchronously', () async {
      final config = SerialConfig(portName: 'COM1');
      final data = Uint8List.fromList([65, 66, 67]); // ABC

      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.readData(any(), any()))
          .thenAnswer((_) async => data);
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);
      final result = await port.readSync();

      expect(result, data);
      verify(() => mockPlatform.readData('COM1', 1024)).called(1);
    });

    test('reads text synchronously', () async {
      final config = SerialConfig(portName: 'COM1');
      final data = Uint8List.fromList([72, 105]); // Hi

      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.readData(any(), any()))
          .thenAnswer((_) async => data);
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);
      final result = await port.readTextSync();

      expect(result, 'Hi');
    });

    test('readSync timeout throws SerialError', () async {
      final config = SerialConfig(
        portName: 'COM1',
        readTimeout: const Duration(milliseconds: 100),
      );

      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.readData(any(), any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return Uint8List(0);
      });
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);

      expect(
        () => port.readSync(),
        throwsA(isA<SerialError>().having(
          (e) => e.type,
          'type',
          SerialErrorType.timeout,
        )),
      );
    });

    test('reads a specific number of bytes', () async {
      final config = SerialConfig(portName: 'COM1');
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.readData(any(), any()))
          .thenAnswer((_) async => data);
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);
      final result = await port.read(5);

      expect(result, data);
      verify(() => mockPlatform.readData('COM1', 5)).called(1);
    });

    test('flush clears the output buffer', () async {
      final config = SerialConfig(portName: 'COM1');
      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.flush(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.empty());

      await port.open(config);
      await port.flush();

      verify(() => mockPlatform.flush('COM1')).called(1);
    });

    test('bytesAvailable returns the number of bytes', () async {
      final config = SerialConfig(portName: 'COM1');
      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.bytesAvailable(any()))
          .thenAnswer((_) async => 42);
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => const Stream.empty());

      await port.open(config);
      final available = await port.bytesAvailable();

      expect(available, 42);
      verify(() => mockPlatform.bytesAvailable('COM1')).called(1);
    });

    test('resetBuffers restores the buffers', () async {
      const config = SerialConfig(portName: 'COM1');
      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.resetBuffers(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => const Stream.empty());

      await port.open(config);
      await port.resetBuffers();

      verify(() => mockPlatform.resetBuffers('COM1')).called(1);
    });

    test('dataStream emits received data', () async {
      const config = SerialConfig(portName: 'COM1');
      final testData = Uint8List.fromList([1, 2, 3]);

      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.value({
                'type': 'data',
                'data': [1, 2, 3],
              }));

      await port.open(config);

      expect(port.dataStream, emits(testData));
    });

    test('textStream emits received text', () async {
      const config = SerialConfig(portName: 'COM1');

      when(() => mockPlatform.openPort(any())).thenAnswer((_) async => {});
      when(() => mockPlatform.getEventStream(any()))
          .thenAnswer((_) => Stream.value({
                'type': 'data',
                'data': [72, 105], // Hi
              }));

      await port.open(config);

      expect(port.textStream, emits('Hi'));
    });
  });
}
